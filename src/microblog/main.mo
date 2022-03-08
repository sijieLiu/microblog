import List "mo:base/List";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
// import Debug "mo:base/Debug";

actor {
  public type Message = {
    text: Text;
    created_at : Int;
  };

  public type Microblog = actor {
    follow: shared(Principal) -> async();
    follows: shared query() -> async[Principal];
    post: shared(Text) -> async();
    posts: shared query() -> async[Message];
    timeline: shared() -> async[Message];
  };

  stable var followed : List.List<Principal> = List.nil(); //empty list

  public shared func follow(id: Principal) : async(){
    followed := List.push(id, followed);
  };

  public shared query func follows() : async [Principal]{
    List.toArray(followed);
  };

  stable var messages : List.List<Message> = List.nil();
 

  public shared(msg) func post(text: Text) : async(){
    //assert(Principal.toText(msg.caller) == "ubtix-jc5ca-34nda-q33zj-ywcse-2dyou-dp7px-nos6x-jbokb-kfggq-nae");
    let message = {
      text = text;
      created_at = Time.now();
    };
    messages := List.push(message, messages)
  };
  
  public shared query func posts(since: Time.Time) : async [Message]{
    var posts_since : List.List<Message> = List.nil();

    for (msg in Iter.fromList(messages)){
      if (msg.created_at > since) {
        posts_since := List.push(msg, posts_since);
      }
    };

    List.toArray(posts_since)
  };

  public shared func timeline(since: Time.Time) : async [Message]{
    var posts_since : List.List<Message> = List.nil();

    for (id in Iter.fromList(followed)){
      let canister : Microblog = actor(Principal.toText(id));
      let msgs = await canister.posts();
      for (msg in Iter.fromArray(msgs)){
          if (msg.created_at > since) {
            posts_since := List.push(msg, posts_since);
          }
      }
    };

    List.toArray(posts_since)
  };

  //  var lastTime = Time.now();
  //  Debug.print(Int.toText(lastTime));

};
