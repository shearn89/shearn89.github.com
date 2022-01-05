---
categories:
- technical
date: "2021-09-15T00:00:00Z"
description: Post detailing the setup for NiFi autojoin rules with IPA
tags:
- blog
- automation
- nifi
featuredImage: "/images/apache-nifi.png"
title: NiFi Autojoining
---

Recently I've been building an Apache NiFi cluster in the cloud. I was looking into how I can configure NiFi to automatically add new nodes to it's cluster, based on using the `Node Group` property that's available within NiFi's `authorizers.xml` configuration file.
<!--more-->
Once you've got your head around how the Authorizer works, this isn't so painful. It involved a good number of queries via `ldapsearch` to get the arguments right, and a "eureka" moment when I remembered there were ways to normalize IDs in the properties file.

This post will serve as a reminder for myself in the future!

## Prerequisites ##

1. An IPA server that you're an admin of
2. A bind user configured on that server or a willingness to put some other ID/password in NiFi

## IPA Automember Rule ##

We need to create an IPA automember rule to add any NiFi hosts to a particular group. This is quick and easy:

```
ipa hostgroup-add --desc="nifi nodes" nifi
ipa automember-add --type=hostgroup nifi
ipa automember-add-condition --type=hostgroup nifi --inclusive-regex='nifi-\d+' --key=fqdn
```

This means any hosts we build that start with the name `nifi-` will automatically be members of the `nifi` hostgroup.

## Login Setup ##

Set up `login-identity-providers.xml` for your IPA config, using the usual settings. Specifically:

```xml
<property name="Url">ldaps://ipa.dev.shearn89.com:636</property>
<property name="User Search Base">cn=accounts,dc=dev,dc=shearn89,dc=com</property>
<property name="User Search Filter">uid={0}</property>
<property name="Identity Strategy">USE_DN</property>
```

This means users can login with a bare username and it'll work fine, and get mapped to the DN.

## Authorizers Setup ##

The `authorizers.xml` setup is the fun bit. Effectively, we need to tell NiFi to find both users and hosts to treat as 'users', and groups and hostgroups (in IPA terms) to act as groups. That way when we specify the Node Group it finds it, and the hosts that are members of it show up as users. As do we!

For my dev environment, the important settings are:

```xml
<property name="User Search Base">cn=accounts,dc=dev,dc=shearn89,dc=com</property>
<property name="User Object Class">ipaobject</property>
<property name="User Search Scope">SUBTREE</property>
<property name="User Search Filter">(|(objectclass=person)(objectclass=ipahost))</property>
<property name="User Identity Attribute"></property>
<property name="User Group Name Attribute">memberOf</property>
<property name="User Group Name Attribute - Referenced Group Attribute"></property>

<property name="Group Search Base">cn=accounts,dc=dev,dc=shearn89,dc=com</property>
<property name="Group Object Class">groupofnames</property>
<property name="Group Search Scope">SUBTREE</property>
<property name="Group Search Filter">(cn=nifi*)</property>
<property name="Group Name Attribute">cn</property>
<property name="Group Member Attribute">member</property>
<property name="Group Member Attribute - Referenced User Attribute"></property>
```

Lets run through some of this (not all):

* User Search Base - the most specific DN to find both users and hosts.
* User Object Class - this needs to be an `objectClass` that both users and hosts have. In our case the only one is `ipaobject`, which is pretty generic. We'll filter this later.
* User Search Filter - this is the LDAP filter to allow us to choose which objects appear as users, otherwise everything does. It's a simple OR query for both `person` and `ipahost`.
* User Identity Attribute - leave blank!
* Group Search Base - similar to User Search Base
* Group Object Class - similarly, an `objectClass` shared by both groups and hostgroups.
* Group Search Filter - a simple search pattern to filter the groups that are displayed.

So what that gives us is both hosts and users showing in NiFi as users, and both groups and hostgroups showing as groups. Excellent!

Problem: names are all different and messed up, and identities can't be matched up. This is where we tie it all together by normalizing things!

## Nifi.properties Setup ##

We use normalization rules in `nifi.properties` to get everything working. This has the added benefit of meaning that you can skip any `Initial Node Identity` entries, and you only need to put an LDAP user as the `Initial Admin Identity` to be able to set up your policies. I'm hoping at some point there'll be an `Initial Admin Group` property that allows you to specify a group, but hey...

The normalization:

```
### LDAP USER
nifi.security.identity.mapping.pattern.user=^uid=(.*?),cn=users,cn=accounts,dc=dev,dc=shearn89,dc=com
nifi.security.identity.mapping.value.user=$1@DEV.SHEARN89.COM
nifi.security.identity.mapping.transform.user=UPPER
### LDAP HOST
nifi.security.identity.mapping.pattern.host=^fqdn=(.*?),cn=computers,cn=accounts,dc=dev,dc=shearn89,dc=com
nifi.security.identity.mapping.value.host=$1
nifi.security.identity.mapping.transform.host=UPPER
### CERT HOST
nifi.security.identity.mapping.pattern.cert=^CN=(.*?), O=DEV.SHEARN89.COM
nifi.security.identity.mapping.value.cert=$1
nifi.security.identity.mapping.transform.cert=UPPER
```

What does this do? Firstly, the `LDAP USER` settings specify that users have the DN matching the specified pattern. Mainly, that they start with `uid=` and are in the `cn=users` OU. We want them to end up as `USER@DOMAIN`, and we transform it all to uppercase.

Secondly for hosts, the DN starts with `fqdn=` and are in `cn=computers`. We don't bother appending the domain and just use the FQDN. This is primarily to pick up the group membership from the automember rule!

Lastly for certificate-based auth (i.e. the nifi nodes themselves), we specify that the identity is pulled from the CN. This is the FQDN in our case, so it means that cert-based identities and LDAP host entries match!

## Results ##

With all this configured, start up your cluster. You should be able to login with the initial admin, go to 'Users', and see a list of all hosts in a nice sensible format. The hostgroup should appear, and all nodes should be able to talk to each other and form the cluster. If you now build a new node, it should automatically be able to join the cluster with no intervention from yourself!
