import List "mo:base/List";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Principal "mo:base/Principal";

actor Mblog {
  public type Message = {
    text: Text;
    created_at : Int;
  };

  public type Microblog = actor {
    follow: shared(Principal) -> async();
    follows: shared query() -> async[Principal];
    post: shared(Text) -> async();
    posts: shared query(Time.Time) -> async[Message];
    timeline: shared(Time.Time) -> async[Message];
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
    assert(Principal.toText(msg.caller) == getPrincipal()); // check principal
    let message = {
      text = text;
      created_at = Time.now();
    };
    messages := List.push(message, messages)
  };
  
  public shared query func posts(since: Time.Time) : async [Message]{
    var posts : List.List<Message> = List.nil();

    for (msg in Iter.fromList(messages)){
      if (msg.created_at >= since) { //filter since
        posts := List.push(msg, posts);
      }
    };

    List.toArray(posts)
  };

  public shared func timeline(since: Time.Time) : async [Message]{
    var all : List.List<Message> = List.nil();

    for (id in Iter.fromList(followed)){
      let canister : Microblog = actor(Principal.toText(id));
      let msgs = await canister.posts(since); //msgs since
      for (msg in Iter.fromArray(msgs)){
        all := List.push(msg, all)
      }
    };

    List.toArray(all)
  };

  public shared func getPrincipal(){
    let a = Principal.fromActor(Mblog)
  }

};
