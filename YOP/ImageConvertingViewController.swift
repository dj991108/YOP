
import Foundation
import UIKit

class ImageConvertingViewController: UIViewController{
    
    var selectedImage: UIImage?  // 변환할 이미지를 저장하는 변수
    var convertedImage: UIImage? // 변환된 이미지를 저장하는 변수
    
    // 화면에서 이미지 생성이 진행 중임을 나타내는 UIActivityIndicatorView
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 화면이 로드될 때 액티비티 인디케이터를 시작
        activityIndicator.startAnimating()
        
        guard let image = selectedImage else { return }
        // 이미지 변환 함수 호출
        convertImageToBase64AndCallAPI(image: image)
    }
    
    
    // Karlo API 입력 이미지 파일 규격 세팅용
    // 1.파일 용량 2MB 이하  2.가로 및 세로 2048 pixel 이하
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? UIImage()
    }
    
    func convertImageToBase64AndCallAPI(image: UIImage) {
        // 이미지 크기 조정 (2048x2048 픽셀 크기로 resize)
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 2048, height: 2048))
    
        // 2MB 이하로 압축과정
        var actualHeight = resizedImage.size.height
        var actualWidth = resizedImage.size.width
        let maxHeight: CGFloat = 2000.0 // max height
        let maxWidth: CGFloat = 2000.0 // max width
        var imgRatio = actualWidth / actualHeight
        let maxRatio = maxWidth / maxHeight
        var compressionQuality: CGFloat = 0.5
    
        if actualHeight > maxHeight || actualWidth > maxWidth {
            if imgRatio < maxRatio {
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if imgRatio > maxRatio {
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else {
                actualHeight = maxHeight
                actualWidth = maxWidth
                compressionQuality = 1
            }
        }
    
        let rect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size)
        resizedImage.draw(in: rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        let imageData = img!.jpegData(compressionQuality: compressionQuality)
        UIGraphicsEndImageContext()
    
        // 이미지 Base64 문자열로 인코딩
        guard let base64String = imageData?.base64EncodedString() else { return }
        callAPIWithBase64Image(base64String: base64String)
    }
    
    // 인코딩된 Base64 이미지 문자열을 사용하여 Karlo API 호출
    // API 호출 결과로 반환되는 Base64 문자열을 다시 이미지로 변환후 convertedImage 속성에 저장
    func callAPIWithBase64Image(base64String: String) {
        let url = URL(string: "https://api.kakaobrain.com/v1/inference/karlo/variations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("KakaoAK \(Config.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody = [
            "prompt": [
                "image": base64String,
                "batch_size": 1
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            print("Error creating JSON from dictionary: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            if let httpResponse = response as? HTTPURLResponse {
                print("Response: \(httpResponse.statusCode)")
            }

            if let data = data, let str = String(data: data, encoding: .utf8) {
                print("Data: \(str)")
            }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            guard let data = data else {
                print("No data found: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let images = json["images"] as? [[String: Any]],
                   let imageDict = images.first,
                   let base64ImageString = imageDict["image"] as? String,
                   let imageData = Data(base64Encoded: base64ImageString),
                   let image = UIImage(data: imageData) {
                    self.convertedImage = image
                    DispatchQueue.main.async {
                        // unwindToMainScreen_convert를 통해 MainScreen으로 변환 이미지 전달 및 화면전환
                        self.performSegue(withIdentifier: "unwindToMainScreen_convert", sender: self)
                    }
                }
            } catch {
                print("JSON decode error: \(error)")
            }
        }
        task.resume() // 네트워크 요청 시작
    }
}
