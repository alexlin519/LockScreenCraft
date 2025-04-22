import Foundation

class EmailService {
    static let shared = EmailService()
    
    private let emailJSServiceID = "your_service_id"
    private let emailJSTemplateID = "your_template_id"
    private let emailJSUserID = "your_user_id"
    
    func sendEmail(
        to: String,
        subject: String,
        body: String,
        attachmentData: Data? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let url = URL(string: "https://api.emailjs.com/api/v1.0/email/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var templateParams: [String: Any] = [
            "to_email": to,
            "subject": subject,
            "message": body
        ]
        
        if let data = attachmentData {
            // Convert image data to base64 for sending
            let base64String = data.base64EncodedString()
            templateParams["attachment"] = base64String
        }
        
        let parameters: [String: Any] = [
            "service_id": emailJSServiceID,
            "template_id": emailJSTemplateID,
            "user_id": emailJSUserID,
            "template_params": templateParams
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(false, "Failed to serialize request: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, "Error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response")
                }
                return
            }
            
            DispatchQueue.main.async {
                if (200...299).contains(httpResponse.statusCode) {
                    completion(true, nil)
                } else {
                    let errorMessage = data != nil ? String(data: data!, encoding: .utf8) : "Unknown error"
                    completion(false, "HTTP Error: \(httpResponse.statusCode) - \(errorMessage ?? "")")
                }
            }
        }.resume()
    }
} 