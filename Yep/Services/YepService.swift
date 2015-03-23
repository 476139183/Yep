//
//  YepService.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation

let baseURL = NSURL(string: "http://park.catchchatchina.com")!

// Models

struct LoginUser: Printable {
    let accessToken: String
    let userID: String
    let nickname: String
    let avatarURLString: String?

    var description: String {
        return "LoginUser(accessToken: \(accessToken), userID: \(userID), nickname: \(nickname), avatarURLString: \(avatarURLString))"
    }
}

struct QiniuProvider: Printable {
    let token: String
    let key: String
    let downloadURLString: String

    var description: String {
        return "QiniuProvider(token: \(token), key: \(key), downloadURLString: \(downloadURLString))"
    }
}

func errorMessageInData(data: NSData?) -> String? {
    if let data = data {
        if let json = decodeJSON(data) {
            if let errorMessage = json["error"] as? String {
                return errorMessage
            }
        }
    }

    return nil
}

// MARK: Register

func validateMobile(mobile: String, withAreaCode areaCode: String, #failureHandler: ((Resource<(Bool, String)>, Reason, NSData?) -> ())?, #completion: ((Bool, String)) -> Void) {
    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
    ]

    let parse: JSONDictionary -> (Bool, String)? = { data in
        println("data: \(data)")
        if let available = data["available"] as? Bool {
            if available {
                return (available, "")
            } else {
                if let message = data["message"] as? String {
                    return (available, message)
                }
            }
        }
        
        return (false, "")
    }

    let resource = jsonResource(path: "/api/v1/users/mobile_validate", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }

}

func registerMobile(mobile: String, withAreaCode areaCode: String, #nickname: String, #failureHandler: ((Resource<(Bool)>, Reason, NSData?) -> ())?, #completion: Bool -> Void) {
    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
        "nickname": nickname,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        if let state = data["state"] as? String {
            if state == "blocked" {
                return true
            }
        }

        return false
    }

    let resource = jsonResource(path: "/api/v1/registration/create", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func verifyMobile(mobile: String, withAreaCode areaCode: String, #verifyCode: String, #failureHandler: ((Resource<LoginUser>, Reason, NSData?) -> ())?, #completion: LoginUser -> Void) {
    let requestParameters: JSONDictionary = [
        "mobile": mobile,
        "phone_code": areaCode,
        "token": verifyCode,
        "client": YepConfig.clientType(),
        "expiring": 0, // 永不过期
    ]

    let parse: JSONDictionary -> LoginUser? = { data in

        if let accessToken = data["access_token"] as? String {
            if let user = data["user"] as? [String: AnyObject] {
                if
                    let userID = user["id"] as? String,
                    let nickname = user["nickname"] as? String {
                        let avatarURLString = user["avatar_url"] as? String
                        return LoginUser(accessToken: accessToken, userID: userID, nickname: nickname, avatarURLString: avatarURLString)
                }
            }
        }

        return nil
    }

    let resource = jsonResource(path: "/api/v1/registration/update", method: .PUT, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

// MARK: Login

func sendVerifyCode(ofMobile mobile: String, withAreaCode areaCode: String, #failureHandler: ((Resource<Bool>, Reason, NSData?) -> ())?, #completion: Bool -> Void) {

    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        if let status = data["status"] as? String {
            if status == "sms sent" {
                return true
            }
        }

        return false
    }

    let resource = jsonResource(path: "/api/v1/auth/send_verify_code", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func loginByMobile(mobile: String, withAreaCode areaCode: String, #verifyCode: String, #failureHandler: ((Resource<LoginUser>, Reason, NSData?) -> ())?, #completion: LoginUser -> Void) {

    let requestParameters: JSONDictionary = [
        "mobile": mobile,
        "phone_code": areaCode,
        "verify_code": verifyCode,
        "client": YepConfig.clientType(),
        "expiring": 0, // 永不过期
    ]

    let parse: JSONDictionary -> LoginUser? = { data in

        if let accessToken = data["access_token"] as? String {
            if let user = data["user"] as? [String: AnyObject] {
                if
                    let userID = user["id"] as? String,
                    let nickname = user["nickname"] as? String {
                        let avatarURLString = user["avatar_url"] as? String
                        return LoginUser(accessToken: accessToken, userID: userID, nickname: nickname, avatarURLString: avatarURLString)
                }
            }
        }
        
        return nil
    }

    let resource = jsonResource(path: "/api/v1/auth/token_by_mobile", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

// MARK: Upload

func publicUploadToken(#failureHandler: ((Resource<QiniuProvider>, Reason, NSData?) -> ())?, #completion: QiniuProvider -> Void) {

    let parse: JSONDictionary -> QiniuProvider? = { data in
        if let provider = data["provider"] as? String {
            if provider == "qiniu" {
                if let options = data["options"] as? [String: AnyObject] {
                    if
                        let token = options["token"] as? String,
                        let key = options["key"] as? String,
                        let downloadURLString = options["download_url"] as? String {
                            return QiniuProvider(token: token, key: key, downloadURLString: downloadURLString)
                    }
                }
            }
        }

        return nil
    }

    let resource = authJsonResource(path: "/api/v1/attachments/public_upload_token", method: .GET, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}


// MARK: Messages

func unreadMessages(#completion: JSONDictionary -> Void) {
    let requestParameters = [
        "per_page": 100,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/messages/unread", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
}

// MARK: Friendships

private func headFriendships(#completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/friendships", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
}

private func moreFriendships(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Resource<JSONDictionary>, Reason, NSData?) -> ())?, #completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/friendships", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func friendships(#completion: [JSONDictionary] -> Void) {

    return headFriendships { result in
        if
            let count = result["count"] as? Int,
            let currentPage = result["current_page"] as? Int,
            let perPage = result["per_page"] as? Int {
                if count <= currentPage * perPage {
                    if let friendships = result["friendships"] as? [JSONDictionary] {
                        completion(friendships)
                    } else {
                        completion([])
                    }

                } else {
                    var friendships = [JSONDictionary]()

                    if let page1Friendships = result["friendships"] as? [JSONDictionary] {
                        friendships += page1Friendships
                    }

                    // We have more friends

                    let downloadGroup = dispatch_group_create()

                    for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                        dispatch_group_enter(downloadGroup)

                        moreFriendships(inPage: page, withPerPage: perPage, failureHandler: { (resource, reason, data) in
                            dispatch_group_leave(downloadGroup)
                        }, completion: { result in
                            if let page1Friendships = result["friendships"] as? [JSONDictionary] {
                                friendships += page1Friendships
                            }
                            dispatch_group_leave(downloadGroup)
                        })
                    }

                    dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                        completion(friendships)
                    }
                }
        }
    }
}

// MARK: Groups

func headGroups(#failureHandler: ((Resource<JSONDictionary>, Reason, NSData?) -> ())?, #completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 1,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/circles", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func moreGroups(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Resource<JSONDictionary>, Reason, NSData?) -> ())?, #completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/circles", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func groups(#completion: [JSONDictionary] -> Void) {
    return headGroups(failureHandler: nil, completion: { result in
        if
            let count = result["count"] as? Int,
            let currentPage = result["current_page"] as? Int,
            let perPage = result["per_page"] as? Int {
                if count <= currentPage * perPage {
                    if let groups = result["circles"] as? [JSONDictionary] {
                        completion(groups)
                    } else {
                        completion([])
                    }

                } else {
                    var groups = [JSONDictionary]()

                    if let page1Groups = result["circles"] as? [JSONDictionary] {
                        groups += page1Groups
                    }

                    // We have more groups

                    let downloadGroup = dispatch_group_create()

                    for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                        dispatch_group_enter(downloadGroup)

                        moreGroups(inPage: page, withPerPage: perPage, failureHandler: { (resource, reason, data) in
                            dispatch_group_leave(downloadGroup)

                        }, completion: { result in
                            if let currentPageGroups = result["circles"] as? [JSONDictionary] {
                                groups += currentPageGroups
                            }
                            dispatch_group_leave(downloadGroup)
                        })
                    }

                    dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                        completion(groups)
                    }

                }
        }
    })
}

