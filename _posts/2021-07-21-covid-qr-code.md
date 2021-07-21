---
layout: post
title: "Covid and QR Codes"
description: "Quick post about decoding the UK passenger locator form data"
category: 
tags: []
---
{% include JB/setup %}

I've had to travel for work over the last few months. Most recently I took a look at the UK Government's Passenger Locator Form - specifically the QR code it produces.

This is quite prominent on the form, and has "UK Government Use Only" all around it, which immediately made me curious!

*Note* - I don't intend for people to use any information here for anything malicious, I encourage everyone to follow the rules that apply around travel! Stay safe everyone!

With that out the way, lets dig in.

# The QR Code #

The form has a QR code right at the top. Here's a screenshot of mine, with some scribbles to redact it - there's a lot of personal info in these!

<img src="/assets/images/passenger-locator-form.png" width="630">

Scanning this with a reader brought back a large string (again, redacted):

<img src="/assets/images/passenger-qr-code-data.png" width="250">

This looked a lot like base64 to me, so I copied the text and ran it through a decoder:

    $ cat qrcode.txt | base64 --decode
    {"ts":"2021-07-17T08:02:00Z","id": ... }

# The Data #

So, I ran it through JQ so my eyes didn't hurt:

    $ cat qrcode.txt | base64 --decode | jq
    {
      "ts": "2021-07-17T08:02:00Z",
      "id": "c8e935cb-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "rf": "UKVI_xxxxxxxxxxxxx",
      "ln": "SHEARN",
      "fn": "ALEXANDER",
      "di": "000000000",
      "tg": [
        {
          "code": "44",
          "number": "1234567890"
        },
        {
          "code": "XXX",
          "number": "111111111"
        }
      ],
      "ac": true,
      "qa": "XXXXXXXXXXXXXX",
      "ad": "2021-07-19",
      "qe": false,
      "rl": false,
      "sn": "MEXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXeZ+w==",
      "ctr": "XXXXXXXXXxxx"
    }

This was kinda cool. It looks like we have a full copy of the passenger locator data here:

* `ts` - timestamp of submission of form
* `id` - uuid for the record in the database
* `rf` - this is the (slightly) more human-readable reference number for the form
* `ln` - last name
* `fn` - first names. This actually had all my names, I've removed some here.
* `di` - this was my passport number, so maybe 'document id'?
* `tg` - this is a list of any contact numbers you've put on the form, with country codes
* `ac` - I think this stands for ????
* `qa` - This is the (at least) first line of my address
* `ad` - arrival date in the UK
* `qe` - I think this stands for "quarantine exempt", so if you're e.g. a haulier you don't have to quarantine on arrival.
* `rl` - Not sure on this one. I wondered if it was something to do with relatives, as you have to declare if this form includes any relatives or just yourself? Or it could be to do with test-to-release?
* `sn` - This is interesting, more on this below
* `ctr` - This is the 'Covid Test Reference' given by the testing provider

So some interesting fields here! Also why you should probably avoid posting any images of the form on social media as it gives someone a lot of info about you!

# The SN Field #

This looked to me like some kind of signature that is used to integrity check the data. Dumping it as hex reveals something that looks like it's got a couple of layers:

    $ cat sn_field | xxd
    00000000: 3044 0220 0e1f df3d 28xx xxxx xxxx xxxx  0D. ............
      ... snip ...
    $ cat sn_field_hex
    30 44 -- header, length of data (44 = 68 bytes)
      02 20 -- same again, but with 32bytes?
        0e 1f df 3d 28     some more interesting data that i'll redact just in case            ac c6 fe
      02 20
        38 d8 14 ec a4     some more interesting data that i'll redact just in case            67 99 fb

I sort of lost interest here as I'm assuming that the key is not stored with the data as that would be pretty dumb!

I expect that what happens is that Border Force scan the QR Code which gets decoded by their systems, and the system removes this `sn` field and then uses it to integrity check the rest of the data. For example:

    $ cat <<EOF> testfile.json
    { "foo": "bar" }
    $ cat testfile.json | sha1sum
    15abb9bce7cf6dc65ab2f6bc6aebfd406448434b  -

So our actual data structure could be:

    {
      "foo": "bar",
      "sn": "15abb9bce7cf6dc65ab2f6bc6aebfd406448434b"
    }

...in this simple example.

# Conclusion #

That's about it - I just thought it was interesting to see what was actually in the barcode! I tried something similar on my NHS vaccination status QR code but it didn't even give me a text string. I suspect that's actual binary data or something else... If you've got ideas, tweet me! [@shearn89](https://twitter.com/shearn89)

./A
