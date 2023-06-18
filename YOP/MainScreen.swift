
import UIKit
import AVFoundation
import Photos // 사진첩 접근용

// WebP 형식의 이미지 저장 가능한 JPEG, PNG 이미지 형식으로 변환 라이브러리
import SDWebImage
import SDWebImageWebPCoder


class MainScreen: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var imageView: UIImageView! // 이미지 표시 view
    
    @IBOutlet weak var placeholderLabel: UILabel! // 사용자 가이드 레이블, 이미지 생성/변환 전에 표시
        
    // imageView 배경색 설정 및 작업결과 설정 & 가이드 Label 숨김/표시 설정
    func setImage(_ image: UIImage?) {
        imageView.image = image // 생성 및 변환된 이미지 표시

        if image != nil {
            imageView.backgroundColor = UIColor.clear
            placeholderLabel.isHidden = true
        } else {
            imageView.backgroundColor = UIColor.systemGray5
            placeholderLabel.isHidden = false
        }
    }
    
    // 저장버튼을 통해 생성/변환된 image 앨범에 저장
    @IBAction func saveImageToPhotosAlbum(_ sender: Any) {
        guard let image = imageView.image else {
            print("이미지가 없습니다.")
            return
        }
        
        // WebP형식의 imageView 이미지를 저장 가능하게(JPEG, PNG) 변환 작업
        
        // SDImageCoder를 사용하여 UIImage를 WebP Data로 변환
        let webPCoder = SDImageWebPCoder.shared
        if let webPData = webPCoder.encodedData(with: image, format: .undefined, options: nil) {

            // WebP Data를 다시 UIImage로 디코딩
            if let decodedImage = webPCoder.decodedImage(with: webPData, options: nil) {
                // 앨범에 저장
                UIImageWriteToSavedPhotosAlbum(decodedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
    
    // 저장 성공 or 실패 여부 팝업 띄우기
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved", message: "앨범에 사진이 저장되었습니다.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    // 'MAKE PHOTO' 버튼을 누르면 'makePhotoSegue'라는 이름의 segue를 수행 -> MakePhoto 컨트롤러 이동
    @IBAction func makePhoto(_ sender: Any) {
        performSegue(withIdentifier: "makePhotoSegue", sender: self)
    }
    
    // 'CONVERT PHOTO' 버튼을 누르면 ImagePicker 표시하여 앨범에서 사진선택
    @IBAction func convertPhoto(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    // 앨범에서 사진 선택시 호출 : 선택한 이미지 가져와서 convertImageSegue 수행
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        picker.dismiss(animated: true) {
            self.performSegue(withIdentifier: "convertImageSegue", sender: image)
        }
    }

    // convertImageSegue 수행시 ImageConvertingViewController로 선택 이미지 전달
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "convertImageSegue", let destinationVC = segue.destination as? ImageConvertingViewController, let image = sender as? UIImage {
            destinationVC.selectedImage = image
        }
    }
    
    // 이미지 생성 후 돌아올 때 호출 -> 생성된 이미지를 imageView에 표시
    @IBAction func unwindToMainScreen(_ unwindSegue: UIStoryboardSegue) {
        if let sourceViewController = unwindSegue.source as? ImageGeneratingViewController {
            setImage(sourceViewController.generatedImage)
        }
    }
    
    // 이미지 변환 후 돌아올 때 호출 -> 변환된 이미지를 imageView에 표시
    @IBAction func unwindToMainScreen_convert(_ unwindSegue: UIStoryboardSegue) {
        if let sourceViewController = unwindSegue.source as? ImageConvertingViewController {
            setImage(sourceViewController.convertedImage)
        }
    }

    
    // 뷰 컨트롤러 실행시 카메라, 앨범접근 권한 확인
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
        checkAlbumPermission()
    }

    // 권한 관련 코드
    func checkCameraPermission(){
       AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
           if granted {
               print("Camera: 권한 허용")
           } else {
               print("Camera: 권한 거부")
           }
       })
    }
    
    //
    func checkAlbumPermission(){
        PHPhotoLibrary.requestAuthorization( { status in
            switch status{
            case .authorized:
                print("Album: 권한 허용")
            case .denied:
                print("Album: 권한 거부")
            case .restricted, .notDetermined:
                print("Album: 선택하지 않음")
            default:
                break
            }
        })
    }
}

