---
categories:
- technical
date: "2021-04-18T00:00:00Z"
description: ""
tags:
- blog
- automation
- nifi
- docker
- python
featuredImage: "/images/apache-nifi.png"
title: Automating NiFi flow testing with Docker and Python
---
I've recently had a dig into automating some NiFi flow testing using Docker and Python. It seemed simple at first, but rapidly became quite complicated. I thought I'd write up some notes, which I hope to improve on when I have more time.
<!--more-->
## First cut

Initially, it was a simple flow in an unsecured cluster. The hardest part here was working out which API call to use to load a flow that had been previously downloaded from a NiFi instance. The magic incantation was this:

1. Load the flow as an object from a JSON file previously downloaded via right-click menu in NiFi
2. Transform the data to wrap it up ready for reload:

```python
  def munge_template(self, data):
    resp = self._get(f"{self.base_url}/process-groups/root")
    resp.raise_for_status()
    revision = resp.json()['revision']
    output = {
      "processGroupRevision": revision,
      "versionedFlowSnapshot": data
    }
    return output
```

3. Then, call PUT on `/process-groups/root/flow-contents` with the output from the above as the data, and it should replace the root process group with the one from your JSON.

There are still some gotchas with this, which may or may not mean you have to refactor your original flow:

* You need to make sure that parameter contexts etc. are stored in the process group on the source flow.
* You can't load sensitive values or parameters this way.
* It will load controller services, but not enable them.
* Remote process groups talking to this cluster will be broken as UUIDs may change.

## Improvements

All in all, it worked okay. My problem was that I wanted to be able to take a copy of the workflow from our staging cluster, load it up in docker and have it all work fine. The main issue with this was that remote processor groups had to have the same URL across both clusters, which means my docker version has to be secured and alias some hostnames...

I set about configuring the container to run in secure mode, by generating some certs and passing them in. So far so good. I then realised I had to load some policies in else the initial admin can't do much. Luckily, I'd previously automated some of that in Python so I could lift and shift the code.

Next, when I loaded in the flow, I remembered that it depended on custom processors. So I set about rebuilding the docker image with the custom NARs bundled in - until I discovered the official NiFi image only runs on Java 8. So I had to rebuild a couple of layers...

Finally, I loaded the flow and bumped into the last 2 bullets on the list above. I had to enable controller services, and also rewire the remote processor groups.

## Last hurdles

Enabling controller services wasn't awful: it was a case of listing them from the root level process group (I have some python code that does a 'walk' of the NiFi tree as part of a monitoring script, so this was easy), then calling a PUT on each one's `/controller-services/{id}/run-status` endpoint in order to set the state to `ENABLED`.

The rewiring of Remote Process Groups (or RPGs) was harder. Effectively I had to:

1. Get the ID of the new input port - my flow just uses RPGs to keep things neat for error handling, so all RPGs point to the same input port
2. Check/update the policy on it to allow receiving site-to-site data
1. On each RPG, call GET to trigger a refresh of the remote ports
2. Check the list of `inputPorts` returned by the GET
3. For each port, check if it's name matches the name of the intended target 
4. If the target port "doesn't exist" according to NiFi, sleep for a few seconds to see if it's still refreshing
5. If it does, enable the port for transmission

NiFi seemed to sort itself out once you'd called refresh, but it's a timing thing: you have to wait for the refresh to occur and then enable the port for transmission. Tedious really.

## Final steps

Once all that is done, you can start your root flow. We have a practice of disabling processors that are not indended to run all the time, as it's easy for someone to accidentally start a whole group and cause an issue. If they're disabled, this can't happen, which also means you can easily start the whole cluster after a failure.


## Remaining Issues

* There's still some oddities since I integrated it with a Kafka node via Docker Compose. Something to do with timing and rebalancing that I've not yet pinned down.
* Sensitive values aren't yet sorted, but I could probably load them from a config file?

./A
