var exec = require('cordova/exec');

var clone = function clone(obj) {
  if (null == obj || "object" != typeof obj) return obj;
  var copy = obj.constructor();
  for (var attr in obj) {
    if (obj.hasOwnProperty(attr) && attr !== '_name') {
      copy[attr] = obj[attr];
    }
  }
  return copy;
};


function CardReader() {

  var _self = this;
  this.handlers = [];

  console.log("CardReader.js: is created");

  var success = function (data) {
    for (var i = 0; i < _self.handlers.length; i++) {
      if (data._name == _self.handlers[i].eventName) {
        _self.handlers[i].handler(clone(data), null);
      }
    }
  };

  var fail = function (data) {
    for (var i = 0; i < _self.handlers.length; i++) {
      if (data._name == _self.handlers[i].eventName) {
        _self.handlers[i].handler(null, clone(data));
      }
    }
  };

  exec(
    success,
    fail,
    "CardReader",
    "initializeCardReader",
    []
  );
}

/*
    Events: ready, read
*/

CardReader.prototype.on = function (eventName, handler) {
  this.handlers.push({
    eventName: eventName,
    handler: handler
  });
};

CardReader.prototype.ready = function (handler) {
  this.on('ready', handler);
};


CardReader.prototype.isReady = function () {
  exec(
    function(ready){
      console.log(ready);
    },
    function(){},
    "CardReader",
    "readIsReady",
    []
  );
};

CardReader.prototype.isConnected = function () {
  exec(
    function(ready){
      console.log(ready);
    },
    function(){},
    "CardReader",
    "readIsConnected",
    []
  );
};

var cardReader = new CardReader();

module.exports = cardReader;