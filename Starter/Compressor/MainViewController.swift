import UIKit

class MainViewController: UIViewController {
  @IBOutlet var jpgSizeLabel: UILabel!
  @IBOutlet var jpgTimeLabel: UILabel!
  @IBOutlet var jpgActivityIndicator: UIActivityIndicatorView!
  @IBOutlet var jpgImageView: UIImageView!
  @IBOutlet var heicSizeLabel: UILabel!
  @IBOutlet var heicTimeLabel: UILabel!
  @IBOutlet var heicActivityIndicator: UIActivityIndicatorView!
  @IBOutlet var heicImageView: UIImageView!
  @IBOutlet var compressionSlider: UISlider!
  
  private let numberFormatter = NumberFormatter()
  
  private let compressionQueue = OperationQueue()

  private var previousQuality: Float = 0
  
  private var originalImage: UIImage = #imageLiteral(resourceName: "jeremy-thomas-unsplash")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Compressor"
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .add,
      target: self,
      action: #selector(addButtonPressed)
    )
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .action,
      target: self,
      action: #selector(shareButtonPressed)
    )
    
    numberFormatter.maximumSignificantDigits = 1
    numberFormatter.maximumFractionDigits = 3
    
    updateImages()
    
    

    compressionSlider.addTarget(
      self,
      action: #selector(sliderEndedTouch),
      for: [.touchUpInside, .touchUpOutside]
    )
  }
  
  // MARK: - Helpers
  
  private func elapsedTime(from startDate: Date) -> String? {
    let endDate = Date()
    let interval = endDate.timeIntervalSince(startDate)
    let intervalNumber = NSNumber(value: interval)
    
    return numberFormatter.string(from: intervalNumber)
  }

  private func resetLabels() {
    jpgSizeLabel.text = "--"
    jpgTimeLabel.text = "--"
    heicSizeLabel.text = "--"
    heicTimeLabel.text = "--"
  }
  
  private func compressJPGImage(with quality: CGFloat) {
    let startDate = Date()

    // Remove the old image and start the activity indicator.
    jpgImageView.image = nil
    jpgActivityIndicator.startAnimating()

    // Add the compression task to the defined operation queue.
    compressionQueue.addOperation {
      // Compress the original image using the quality parameter and convert it to Data.
      guard let data = self.originalImage.jpegData(compressionQuality: quality) else {
        return
      }
      
      // Create a UIImage from the compressed data and update the image view on the main thread. Remember that UI manipulation should always happen on the main thread. You’ll be adding a more code to this method soon.
      DispatchQueue.main.async {
        self.jpgImageView.image = UIImage(data: data)
        self.jpgSizeLabel.text = data.prettySize
        
        if let time = self.elapsedTime(from: startDate) {
          self.jpgTimeLabel.text = "\(time) s"
        }
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        
        UIView.animate(withDuration: 0.3) {
          self.jpgActivityIndicator.stopAnimating()
        }
      }
    }

  }
  
  private func compressHEICImage(with quality: CGFloat) {
    let startDate = Date()

    heicImageView.image = nil
    heicActivityIndicator.startAnimating()

    compressionQueue.addOperation {
      do {
        let data = try self.originalImage.heicData(compressionQuality: quality)
        
        DispatchQueue.main.async {
          self.heicImageView.image = UIImage(data: data)
          self.heicSizeLabel.text = data.prettySize
          if let time = self.elapsedTime(from: startDate) {
            self.heicTimeLabel.text = "\(time) s"
          }
          self.navigationItem.leftBarButtonItem?.isEnabled = true
          
          UIView.animate(withDuration: 0.3) {
            self.heicActivityIndicator.stopAnimating()
          }
        }
      } catch {
        print("Error creating HEIC data: \(error.localizedDescription)")
      }
    }

  }
  
  private func updateImages() {
    navigationItem.leftBarButtonItem?.isEnabled = false

    let quality = CGFloat(compressionSlider.value)
    
    compressionQueue.cancelAllOperations()

    resetLabels()
    compressJPGImage(with: quality)
    compressHEICImage(with: quality)
  }
  
  private func shareImage(_ image: UIImage) {
    let avc = UIActivityViewController(
      activityItems: [image],
      applicationActivities: nil
    )
    present(avc, animated: true)
  }

  // MARK: - Actions
  
  @objc private func addButtonPressed() {
    let picker = UIImagePickerController()
    picker.delegate = self

    present(picker, animated: true)
  }
  
  @objc private func shareButtonPressed() {
    let avc = UIAlertController(
      title: "Share",
      message: "How would you like to share?",
      preferredStyle: .alert
    )

    if let jpgImage = jpgImageView.image {
      avc.addAction(UIAlertAction(title: "JPG", style: .default) { _ in
        self.shareImage(jpgImage)
      })
    }

    if let heicImage = heicImageView.image {
      avc.addAction(UIAlertAction(title: "HEIC", style: .default) { _ in
        self.shareImage(heicImage)
      })
    }

    avc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

    present(avc, animated: true)
  }
  
  @objc private func sliderEndedTouch() {
    updateImages()
  }

  @objc private func sliderDidChange() {
    let diff = abs(compressionSlider.value - previousQuality)
    
    guard diff > 0.1 else {
      return
    }
    
    previousQuality = compressionSlider.value
    
    updateImages()
  }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    // Dismiss the picker when the cancel button gets pressed.
    picker.dismiss(animated: true)
  }
  
  func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo
      info: [UIImagePickerController.InfoKey : Any]
    )
  {
    picker.dismiss(animated: true)
    
    // Get the original image from the picker for the best results in this app.
    guard let image = info[.originalImage] as? UIImage else {
      return
    }
    
    // Store this image and update the image views.
    originalImage = image
    updateImages()
  }
}
