//
//  NetworkManager+Extention.swift
//  SinaWebo
//
//  Created by Hearsay on 2016/12/29.
//  Copyright © 2016年 Hearsay. All rights reserved.
//

import Foundation

/// 封装新浪微博的请求方法
extension NetworkManager {
    
    /// 加载微博首页数据（字典数组）
    func statusList(since_id: Int64 = 0, max_id: Int64 = 0, complentionRequest: @escaping (_ list: [[String : Any]]?, _ isSuccess:Bool) -> ()) {
        
        let urlString = "https://api.weibo.com/2/statuses/home_timeline.json"
        
        let paramet = ["since_id" : "\(since_id)", "max_id" : "\(max_id > 0 ? max_id - 1 : 0)"]
        
        accessTokenRequest(urlString: urlString, parameters: paramet) { (json, isSuccess)->() in
            
            let dict = json as? [String : Any]
            
            let result = dict?["statuses"] as? [[String : Any]]
            
            complentionRequest(result, isSuccess)
        }
    }
    
    /// 获取微博未读数量
    func unreadCount(complention: @escaping (_ unreadCount: Int) -> ()) {
        
        let url = "https://rm.api.weibo.com/2/remind/unread_count.json"
        
        accessTokenRequest(urlString: url, parameters: ["uid" : userAccount.uid ?? ""]) { (json, isSuccess) -> () in

            let dict = json as? [String : Any]
            
            let count = dict?["status"] as? Int ?? 0
            
            complention(count)
        }
    }
    
    /// 获取access_token
    func loadAccessToken(code: String, completion: @escaping (_ isSuccess: Bool) -> ()) {
        
        let url = "https://api.weibo.com/oauth2/access_token"
        
        let paramters = [
            "client_id"     : AppKey,
            "client_secret" : AppSecret,
            "grant_type"    : "authorization_code",
            "code"          : code,
            "redirect_uri"  : RedirectUrl
        ]
        
        request(method: .Post, URLString: url, parameters: paramters) { (json, isSuccess) in
            
            // 设置账号信息
            self.userAccount.yy_modelSet(with: (json as? [String : Any] ?? [:]))
            
            // 获取用户个人信息
            self.loadUserInfo(completion: { (userDict) in
                
                self.userAccount.yy_modelSet(with: userDict)
                
                self.userAccount.savaAccount() // 保存信息到本地
                
                print(self.userAccount)
                
                completion(isSuccess)
            })
        }
    }
    

    /// 发布一条微博信息
    ///
    /// - Parameters:
    ///   - text: 需要发送的微博文本
    ///   - image: 需要发送的微博图片，若为nil，则发送纯文本微博
    ///   - completion: 完成回调
    func postStatus(text: String, image: UIImage? = nil, completion: @escaping (_ json: [String : Any]?, _ isSuccess: Bool) -> ()) {
        
        let params = ["status" : text]
        
        let urlString: String
        var name: String? = nil
        var data: Data? = nil
        
        if image == nil {
            urlString = "https://api.weibo.com/2/statuses/update.json"
        } else {
            urlString = "https://upload.api.weibo.com/2/statuses/upload.json"
            name = "pic"
            data = UIImagePNGRepresentation(image!)
        }
        
        
        accessTokenRequest(method: .Post, urlString: urlString, parameters: params, name: name, data: data) { (json, isSuccess) in
            completion(json as? [String : Any], isSuccess)
        }
        
    }
    
    /// 加载微博用户个人信息
    private func loadUserInfo(completion: @escaping (_ dict: [String : Any]) -> ()) {
        
        let urlString = "https://api.weibo.com/2/users/show.json"
        
        let parameters = ["uid" : userAccount.uid ?? ""]
        
        accessTokenRequest(urlString: urlString, parameters: parameters) { (json, isSuccess) -> () in
            
            completion(json as? [String : Any] ?? [:])
        }
    }
}
