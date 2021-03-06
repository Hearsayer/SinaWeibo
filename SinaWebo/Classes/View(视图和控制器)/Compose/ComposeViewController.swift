//
//  ComposeViewController.swift
//  SinaWebo
//
//  Created by Hearsay on 2017/1/22.
//  Copyright © 2017年 Hearsay. All rights reserved.
//

import SVProgressHUD

class ComposeViewController: UIViewController {
    
    /// 文字视图
    @IBOutlet weak var textView: ComposeTextView!
    
    /// 底部工具栏
    @IBOutlet weak var toolBar: UIToolbar!
    
    /// 标题视图
    @IBOutlet weak var titlelabel: UILabel!
    
    /// 工具条底部约束
    @IBOutlet weak var toolbarBottomCons: NSLayoutConstraint!
    
    fileprivate lazy var photoView: ComposePhotosView = {
        let view = ComposePhotosView(frame: CGRect(x: 10, y: 200, width: UIScreen.main.bounds.width - 20, height: 200))
        view.backgroundColor = UIColor.red
        return view
    }()
    
    /// 发布按钮
    fileprivate lazy var composeButton: UIButton = {
        
        let btn = UIButton()
        btn.setTitleColor(UIColor.orange, for: .normal)
        btn.setTitle("发布", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(composeStatus), for: .touchUpInside)
        btn.sizeToFit()
        return btn
    }()
    /*
    /// 发送给服务器的文本
    fileprivate var emotionText: String? {
        
        var result = ""
        
        // 遍历输入视图的属性字符串
        textView.attributedText.enumerateAttributes(in: NSRange(location: 0, length: textView.attributedText.length), options: []) { (dict, range, _) in
            print(dict)
            if let attachment = dict["NSAttachment"] as? EmoticonTextAttachment {
                result += attachment.chs ?? ""
            } else {
                result += (textView.attributedText.string as NSString).substring(with: range)
            }
        }
        return result
    }
    */
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        view.addSubview(photoView)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", target: self, action: #selector(back))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: composeButton)
        navigationItem.titleView = titlelabel
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewTextDidChange), name: NSNotification.Name.UITextViewTextDidChange, object: textView)
        
        textViewTextDidChange()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    @IBAction func choosePhoto() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    /// 切换表情键盘
    @IBAction func emoticonKeyboard(_ sender: UIButton) {
        
        if textView.inputView == nil {
            
            let v = EmoticonInputView.inputView { [weak self] (emotion) in
                
                emotion == nil ? self?.textView.deleteBackward() : self?.textView.insert(emotion: emotion!)
            }
            
            textView.inputView = v
        } else {
            textView.inputView = nil
        }
        textView.reloadInputViews()
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ComposeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
        
        photoView.addPhoto(photo: image)
        
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ComposeViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textViewTextDidChange()
    }
}


// MARK: - 事件处理
private extension ComposeViewController {
    
    @objc func textViewTextDidChange() {
        textView.placeholderLabel.isHidden = textView.hasText
        composeButton.isHidden = !textView.hasText
    }
    
    /// 键盘通知事件
    @objc func keyboardChange(n: Notification) {
        
        guard let rect = (n.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue)?.cgRectValue,
            let time = (n.userInfo?["UIKeyboardAnimationDurationUserInfoKey"] as? NSNumber)?.doubleValue else { return }
        
        toolbarBottomCons.constant = view.bounds.height - rect.origin.y
        
        UIView.animate(withDuration: time) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// 返回
    @objc func back() {
        dismiss(animated: true, completion: nil)
    }
    
    /// 发微博
    @objc func composeStatus() {
        
        SVProgressHUD.show()
        
        NetworkManager.shared.postStatus(text: textView.emotionText, image: photoView.photos.first) { (json, isSuccess) in
            
            if isSuccess {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                    
                    SVProgressHUD.showSuccess(withStatus: "发布成功！")
                    self.back()
                })
            } else {
                
                SVProgressHUD.showSuccess(withStatus: "发布失败！")
            }
        }
    }
}
