import SwiftUI

struct ContentView: View {
    // 用户输入的文本
    @State private var userInput = ""
    
    // AI 的回复
    @State private var aiResponse = ""
    
    @State private var isThinking = false  // 思考状态变量
    
    // API 调用函数
    func sendRequest(userInput: String) {
        isThinking = true  // 开始请求时设置为思考状态
        aiResponse = "正在思考..."  // 显示思考中的提示
        
        let apiUrl = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        let apiKey = "7cdbd58c267c4cba19ac8d397a19c96f.ZHfyHC4Fi4qq0Xyv" // 请替换为你的 API 密钥
        
        // 创建请求内容
        let requestBody: [String: Any] = [
            "model": "glm-4",
            "messages": [
                ["role": "user", "content": userInput]
            ],
            "top_p": 0.7,
            "temperature": 0.9
        ]
        
        // 将请求内容转为 JSON 数据
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Error: Failed to create request data.")
            return
        }

        // 创建 URL 请求
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")  // 添加这行
        request.httpBody = requestData
        
        // 创建网络请求任务
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isThinking = false  // 请求完成时取消思考状态
            }
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received.")
                return
            }
            
            // 解析 JSON 响应
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Debug - Full response: \(jsonResponse)") // 添加调试输出
                    
                    if let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            self.aiResponse = content
                        }
                    } else {
                        print("Debug - Parsing failed") // 添加调试输出
                        DispatchQueue.main.async {
                            self.aiResponse = String(data: data, encoding: .utf8) ?? "Error: Could not decode response"
                        }
                    }
                }
            } catch {
                print("Debug - JSON parsing error: \(error)") // 添加调试输出
                DispatchQueue.main.async {
                    self.aiResponse = "Error: \(error.localizedDescription)"
                }
            }
        }
        
        // 启动任务
        task.resume()
    }

    var body: some View {
        VStack {
            // 显示 AI 回复的区域
            ScrollView {
                Text(aiResponse)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(isThinking ? 0.6 : 1)  // 思考时文字显示为半透明
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            // 用户输入框
            TextField("请输入你的问题...", text: $userInput)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // 提交按钮
            Button(action: {
                sendRequest(userInput: userInput)
                userInput = "" // 清空输入框
            }) {
                Text("发送")
                    .padding()
                    .foregroundColor(.white)
                    .background(userInput.isEmpty ? Color.gray : Color.blue) // 根据输入状态改变颜色
                    .cornerRadius(8)
            }
            .disabled(userInput.isEmpty) // 当输入为空时禁用按钮
            .padding()
        }
        .padding()
    }}

@main
struct OpenAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
