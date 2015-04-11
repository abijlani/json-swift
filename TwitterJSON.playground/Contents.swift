/*:
# JSON + Swift: Functionally Beautiful
## Amit Bijlani
### @paradoxed
*/

import UIKit
import XCPlayground

XCPSetExecutionShouldContinueIndefinitely(continueIndefinitely: false)

let fileName = "Timeline"
let fileExtension = "json"

/*:
## Type aliases
*/

typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>


/*:
## The Either Type
### Either an error or a valid value which has to be stored in a generic container defined below as Box
*/

enum Result<A> {
  case Error(NSError)
  case Value(Box<A>)
}


final class Box<A> {
  let value: A
  
  init(_ value: A) {
    self.value = value
  }
}


/*:
## Monad Bind Operator
### Binds an Optional to a Function that takes a non-optional and returns an Optional
*/


infix operator >>> { associativity left precedence 150 }

func >>><A, B>(a: A?, f: A -> B?) -> B? {
  if let x = a {
    return f(x)
  } else {
    return .None
  }
}


/*:
## Functors `fmap`
### Applying functions to values wrapped in an Optional
*/


infix operator <^> { associativity left } // Functor's fmap (usually <$>)

func <^><A, B>(f: A -> B, a: A?) -> B? {
  if let x = a {
    return f(x)
  } else {
    return .None
  }
}

/*:
## Applicatives functors `apply`
### Applying wrapped functions to values wrapped in an Optional
*/

infix operator <*> { associativity left } // Applicative's apply

func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
  if let x = a {
    if let fx = f {
      return fx(x)
    }
  }
  return .None
}

/*:
## Casting Functions
*/

func JSONToString(object: JSON) -> String? {
  return object as? String
}

func JSONToInt(object: JSON) -> Int? {
  return object as? Int
}

func JSONToDictionary(object: JSON) -> JSONDictionary? {
  return object as? JSONDictionary
}

func JSONToArray(object: JSON) -> JSONArray? {
  return object as? JSONArray
}

/*:
## User model
### Note the currying function named create
*/

struct User {
  let name: String
  let profileDescription: String
  let followersCount: Int
  
  static func create(name: String)(profileDescription: String)(followersCount: Int) -> User {
    return User(name: name, profileDescription: profileDescription, followersCount: followersCount)
  }
  
}

/*:
## parseData
### Takes a data parameter and the second parameter is a callback function that returns a Result enum.
*/

func parseData(data: NSData?, callback: (Result<User>) -> ())  {
  var jsonErrorOptional: NSError?
  let jsonObject: AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: &jsonErrorOptional)
  
  if let err = jsonErrorOptional {
    callback(.Error(err))
    return
  }
  
  if let statuses = jsonObject >>> JSONToArray,
          aStatus = statuses[0] >>> JSONToDictionary,
   userDictionary = aStatus["user"] >>> JSONToDictionary {
    
      let user = User.create <^>
        userDictionary["name"] >>> JSONToString <*>
        userDictionary["description"] >>> JSONToString <*>
        userDictionary["followers_count"] >>> JSONToInt

      if let u = user {
        callback(.Value(Box(u)))
        return
      }
  }
  
		// if all else fails return error
  callback(.Error(NSError()))
}

/*:
## Calling `parseData`
*/

//read
let bundle = NSBundle.mainBundle()
let data = NSData(contentsOfURL: bundle.URLForResource(fileName, withExtension: fileExtension)!)

parseData(data){result in
  switch result {
  case let .Error(err):
    print("Error \(err)")
    
  case let .Value(username):
    print(username.value.name)
  }
}
  

