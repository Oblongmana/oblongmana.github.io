---
layout: page
title: "Gist Dex Release Notes - v1.2.0"
description: "Gist Dex v1.2.0 Release Notes - A Collaborative Index of Gists for users within an organization"
categories: gistdex release-notes
tags: [salesforce, gist, gistdex, release-notes]
colorbar: salesforce
comments: true
---

Version 1.2.0
-------------
Released 1st April 2013

#### Major Features
 -  Result collapsing now uses Bootstrap accordion, shows both name AND description (much easier to click on, and better looking)
 -  Gist file contents now show in the extremely pretty ACE editor, which has been set up to try really hard to get the right syntax highlighting depending on the type of file(s) in your gist (That means you can edit Gists locally in browser. And they're pretty).
 -  Gist file contents can be copied to clipboard (using ZeroClipboard) by clicking on the File's name button (and that includes any edits you make in-browser)
 -  Gist Search results are now paginated to 5 Gists per page
 -  Gists can now be selectively inserted, instead of only being able to add one or all of your Gists

#### Minor Features
 - Pages have titles, to help taboholics locate them.

#### Bug Fixes
 - If you request more than 30 Gists at a time, the 31st onwards Gists will be retrieved. Previously, Gist Dex did not handle GitHub's response pagination
 - Dexes will not be duplicated if a Gist is added that uses one. See also the Admin section below

#### Admin
 - A post-install script has been added to ensure there are no duplicate Dexes. Any Gists pointing to the duplicate Dexes will point to the non-duplicate Dex afterwards.
