
import Foundation
import UIKit

class ImageGeneratingViewController: UIViewController {

    var promptText: String? // MakePhoto로부터 전달받은 promptText
    var generatedImage: UIImage? // 생성 이미지를 저장하는 변수

    // 화면에서 이미지 생성이 진행 중임을 나타내는 UIActivityIndicatorView
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 화면이 로드될 때 액티비티 인디케이터를 시작
        activityIndicator.startAnimating()
        
        // promptText를 바탕으로 이미지를 생성하는 함수 호출
        generateImage(from: promptText!) { image in
            DispatchQueue.main.async { // main 쓰레드에서 작업 수행 ( api작업은 네트워킹 요청을 수반하므로 "비동기적 작업"이 필수적 -> 이미지 생성이 완료되어야만 unwindsegue작업을 수행하고, 스케줄링이 꼬이는 오류를 방지하여 MainScreen의 ImageView에 이미지가 전달되는것을 보장한다.
                self.generatedImage = image  // 생성 이미지 할당
                self.activityIndicator.stopAnimating() // 완료시 액티비티 인디케이터 작동 중지
                // unwindToMainScreen를 통해 MainScreen으로 생성 이미지 전달 및 화면전환
                self.performSegue(withIdentifier: "unwindToMainScreen", sender: self)
            }
        }
    }

    // generateImage 메서드 : promptText를 restApi형식 요청을 보내, 응답으로 결과물 이미지 받기
    func generateImage(from text: String, completion: @escaping (UIImage?) -> Void) {
        // REST API의 엔드포인트 URL 설정
        let url = URL(string: "https://api.kakaobrain.com/v1/inference/karlo/t2i")!
        var request = URLRequest(url: url)
        // 데이터 형식 JSON
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 인증 헤더 : Authorization: KakaoAK ${REST_API_KEY}
        request.setValue("KakaoAK \(Config.apiKey)", forHTTPHeaderField: "Authorization")
        // HTTP 메서드 : POST
        request.httpMethod = "POST"
        // JSON 요청 본문을 생성
        let json: [String: Any] = ["prompt": ["text": text, "batch_size": 1]]
        // Data 객체로 변환
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        // HTTP 요청 바디 작성
        request.httpBody = jsonData

        // URLSession을 사용하여 네트워크 요청
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print("No data found: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                // json 응답 데이터 디코딩
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    // 이미지 데이터 추출
                    if let images = json["images"] as? [[String: Any]], let imageDict = images.first, let base64ImageString = imageDict["image"] as? String {
                        // base64 인코딩된 문자열 형태의 이미지 데이터 디코딩 -> UIImage 객체로 변환
                        if let imageData = Data(base64Encoded: base64ImageString), let image = UIImage(data: imageData) {
                            completion(image)
                        } else {
                            completion(nil)
                        }
                    }
                }
            } catch {
                print("JSON decode error: \(error)")
            }
        }
        task.resume() // 네트워크 요청 시작
    }
}
