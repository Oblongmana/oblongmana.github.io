---
layout: post
title: "Angular - 3rd Party Injection"
description: "Convert third party libraries into Angular services quickly, with minimal pollution"
category: articles
tags: [angular,third-party libraries,injection]
image:
    thumb: posts/pageMessageSamples.png
colorbar: salesforce
comments: true
---

Angular developers, often find themselves needing to use a third party library in a hurry, and either the third party library is not itself Angular-ready, you can't find an Angular-wrapped version of it on github/bower/whatever, or the Angular-wrapped version you find is unsuitable for your purposes, out of date, or buggy.

In these cases, it's pretty tempting to just add the library to your page scripts, and either tell jshint the library is a global and just use it everywhere in your code (gross), or inject `$window` into anything you want to use that third party library (gross, but slightly less so).

For example, using momentjs:
{% highlight javascript %}
//Import moment.js into your page
<script type="text/javascript"
        src="//cdnjs.cloudflare.com/ajax/libs/moment.js/2.8.3/moment.js"/>

//Just using it globally (gross)
angular.module('myApp').factory('myService',[function(){
  console.log('urgh, gross, global moment', moment());
  ...
}]);

//Accessing it right off $window (slightly less gross)
angular.module('myApp').factory('myService',['$window',function($window){
  console.log('hmm, slightly less gross, getting moment from $window', $window.moment());
}]);
{% endhighlight %}


Really though, it would be better if *momentjs* were a module that provided a service you could inject. Makes for more angular-idiomatic code, more sensible testing, and just feels better.

So I've started using a relatively simple pattern for accomplishing just that. **Disclaimer:** there may well be better ways to do this, I've just found this method to be nice and quick, and play well with karma for testing.

The basic principle is that for each third party library you want to use, you're going to make a new module named after that library, and it's going to provide a service whose name is whatever you were previously using as the global to access it. So for moment.js, our module will be called `momentjs`, and our service will be called `moment`. That means that we will (in a normal use case), make our app dependent on `momentjs`, and inject `moment` into anything that wants to use *momentjs* functionality.

However, I also want `moment` to no longer be attached to `window`, so I (and any other devs on the project) can't just use `window.moment` globally. So we're going to delete `window.moment` (there are some caveats to this as well, which I'll cover after this code example). So, here's how we do it

{% highlight javascript %}
//Import moment.js into your page as always
<script type="text/javascript"
        src="//cdnjs.cloudflare.com/ajax/libs/moment.js/2.8.3/moment.js"/>

//Before your main app module is declared, declare a momentjs module
angular.module('momentjs',[])
  //And on the momentjs module, declare the moment service that we want
  // available as an injectable
  .factory('moment', function ($window) {
    if($window.moment){
      //Delete moment from window so it's not globally accessible.
      //  We can still get at it through _thirdParty however, more on why later
      $window._thirdParty = $window._thirdParty || {};
      $window._thirdParty.moment = $window.moment;
      try { delete $window.moment; } catch (e) {$window.moment = undefined;
      /*<IE8 doesn't do delete of window vars, make undefined if delete error*/}
    }
    var moment = $window._thirdParty.moment;
    return moment;
  });

//In your app creation, make your app dependent on the momentjs module we just
// made, so we can get at its services
angular.module('myApp', ['momentjs']);

//Now we can inject moment as a service!!!
angular.module('myApp').factory('myService',['moment',function(moment){
  console.log('Wow, such clean access to moment as a service', moment());
}]);

//And if we try to use moment on a module that hasn't injected it, it will
// throw an error instead of grabbing the global moment off window
angular.module('myApp').factory('myBadService',[function(){
  try {
    moment();
  }
  catch(e) {
    console.log('moment is not available globally! Globals bad. '+
      'You have to inject it');
  }
}]);
{% endhighlight %}

So now - `window.moment` isn't polluting `window` and can't just be used as a global, but instead has to be injected into anything that wants to use it.

You'll have noticed in the code example that it wasn't just a simple case of deleting `window.moment` however. If your app doesn't have unit tests at all (which would be bad, don't do it!), then instead of the `moment` factory method above, you could probably safely rewrite it as follows:

{% highlight javascript %}
angular.module('momentjs',[]).factory('moment', function ($window) {
  //Simply grab moment off window, then delete moment off window
  var moment = $window.moment;
  try { delete $window.moment; } catch (e) {$window.moment = undefined;
  /*<IE8 doesn't do delete of window vars*/}
  return moment;
});
{% endhighlight %}

However, if your app does have karma unit tests, you'll find that your modules are actually getting created once per spec. After the first spec runs, you'll find that `moment` no longer works, and your tests all break in horrifying ways.

This is because in the first run, you delete `window.moment`. That's not a problem for your first spec, because before you deleted `window.moment`, your service grabbed a reference to it, so your app can access `moment` through the service.

In the second and subsequent specs however, `window.moment` has **already** been deleted, so when the test runner tries to create the `momentjs` module for the second and subsequent tests, it fails, because `window.moment` is gone and your `momentjs` module (being created in second and subsequent specs) can't grab a reference to `moment` to return when creating the service.

As such, the example I give moves moment out of the window/global namespace onto `window._thirdParty`. This means that you can't just grab at moment globally without making a conscious decision to misbehave by getting it via `window._thirdParty`, and it means that instead of heaving one window property for every third party library you add, they're all hidden in a single `_thirdParty` property. Karma will be able to succesfully create the momentjs module as many times as it likes as well, as your module creation code gets the moment reference from `_thirdParty` (or moves moment to `_thirdParty` if it hasn't already, THEN retrieves the moment reference from `_thirdParty`);

