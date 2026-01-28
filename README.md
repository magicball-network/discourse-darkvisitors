# Discourse Dark Visitors Plugin

This [Discourse](https://discourse.com) plugin adds an integration with [Dark Visitors](https://darkvisitors.com). 
Via Dark Visitors you will get some insights into which bots or scrapers visit your forum.

It provides the following features:

- augmenting robots.txt 
- server analytics
- client analytics

In order to use this plugin you need to sign up with [Dark Visitors](https://darkvisitors.com).

For more information and discussion see [this thread](https://meta.discourse.org/t/dark-visitors/365158) on the Discourse Meta forum.

## Plugin Compatibility Status

[![Discourse latest](https://github.com/magicball-network/discourse-darkvisitors/actions/workflows/latest.yml/badge.svg)](https://github.com/magicball-network/discourse-darkvisitors/actions/workflows/latest.yml)

[![Discourse ESR](https://github.com/magicball-network/discourse-darkvisitors/actions/workflows/esr.yml/badge.svg)](https://github.com/magicball-network/discourse-darkvisitors/actions/workflows/esr.yml)

The above status is based on the plugin's executed tests against the specified Discourse branch.
It is no definite guarantee that there no issues.

## Augmenting robots.txt

With this enabled the robots.txt file created by Discourse will be augmented with [agents](https://darkvisitors.com/agents) from the configured categories.
Once a day the latest list of agents is retrieved and the robots.txt is updated accordingly.
Only agents which are not already registered in the robots.txt are added.

This can be used to instruct AI scrapers and other bots to exclude your forum.

This feature only works if you have not manually overridden robots.txt.

## Server Analytics

Requests to the server are reported to Dark Visitors.

This feature can be enabled for everybody, or only unauthenticated users (recommended).

## Client Analytics

A javascript based tracker is added to the forum which, under certain conditions, will report back to Dark Visitors.

At the moment of writing under the following conditions trigger a callback to Dark Visitors:
- User is referred to the forum from an AI service
- The browser might be a scraper

This feature can be enabled for everybody, or only unauthenticated users.
