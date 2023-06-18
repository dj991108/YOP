

import UIKit

class MakePhoto: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var inputKeywords: UITextField! // 생성할 이미지 키워드 입력 TextField
    @IBOutlet weak var selectStyle: UIPickerView! // 작가 스타일 선택 PickerView
        
    var artists = ["None", "Van Gogh", "Picasso", "Monet", "Da Vinci", "Michelangelo", "Salvador Dali", "Rembrandt", "Johannes Vermeer"] // 선택 가능한 작가 스타일 목록
    var selectedArtist: String?
    
    // 키워드(필수) 및 작가 스타일(선택)을 설정 후, "이미지생성"버튼을 누르면 imageGeneratingSegue를 통해 ImageGeneratingViewController로 이동
    @IBAction func makingPhoto(_ sender: Any) {
        guard let keywords = inputKeywords.text else { return }
        var promptText = keywords
        if let artist = selectedArtist, artist != "None" {
            promptText += " by \(artist)"
        }
        performSegue(withIdentifier: "imageGeneratingSegue", sender: promptText)
    }
    
    // imageGeneratingSegue 수행시 ImageGeneratingViewController로
    // promptText(이미지생성 파라메타 문장) 전달
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageGeneratingSegue", let imageGeneratingViewController = segue.destination as? ImageGeneratingViewController, let promptText = sender as? String {
            imageGeneratingViewController.promptText = promptText
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // pickerView의 delegate와 dataSource 설정
        selectStyle.delegate = self
        selectStyle.dataSource = self
        inputKeywords.delegate = self
    }
    
    
    // pickerView 하나의 컴포넌트
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // pickerView 행의 수는 스타일 목록의 길이
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return artists.count
    }
    
    // pickerView 각 행 제목은 스타일 이름
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return artists[row]
    }
    
    // pickerView 행 선택시, 해당 내용 selectedArtist로 설정
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedArtist = artists[row]
    }
}
