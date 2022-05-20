// Persistent logger keeping track of what is going on.

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import TextLogger "TextLogger";
import Logger "mo:ic-logger/Logger";

actor class TextLoggers() {
  let maxCapacity: Nat = 100;

  stable var loggerList: List.List<TextLogger.TextLogger> = List.nil();
  stable var count: Nat = maxCapacity;

  public shared (msg) func append(msgs: [Text]) : async () {
    
    if (count == maxCapacity){
      let logger: TextLogger.TextLogger = await TextLogger.TextLogger();
      count := 0;
      loggerList := List.push(logger, loggerList);      
    };
    let o: ?TextLogger.TextLogger = List.get(loggerList, 0);    
    switch o {
      case (?logger) { 
        await logger.append(msgs);
        count := count + 1;        
      };
      case null {  };
    }
    
  };

  // Return the messages between from and to indice (inclusive).
  public shared func view(from: Nat, to: Nat) : async Logger.View<Text> {
    assert(to >= from);
    let buf = Buffer.Buffer<Text>(to - from + 1);
    let start_index:Nat = from / maxCapacity;
    let end_index:Nat = (to + maxCapacity-1) / maxCapacity;

    let length:Nat = List.size(loggerList)-1;
    let loop_end =if (end_index > length) { length } else { end_index };
    
    let arr = List.toArray(loggerList);
    
    var offset = start_index * maxCapacity;

    var i=start_index;
    while (i <= loop_end) {
        let lg = arr[arr.size()-1-i];    
        let view = await lg.view(0, maxCapacity);
        var j = 0;
        while (j < view.messages.size()) {
          if (offset >= from and offset <= to){
            let msg = view.messages[j];
            buf.add(msg);
          };

          offset := offset +1;
          j := j+1;
        };
        i := i+1;
    };
    {
      start_index = from;
      messages = buf.toArray();
    }

    // var all: List.List<Logger.View<Text>> = List.nil();
    // for ( lg in Iter.fromList(loggerList)){
    //     let view = await lg.view(0, maxCapacity);
    //     all := List.push(view, all);
    // };
    // all
  };

}