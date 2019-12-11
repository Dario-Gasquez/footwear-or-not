//
//  ViewController.swift
//  FootwearOrNot
//
//  Created by Dario on 12/10/19.
//  Copyright © 2019 Dario. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO


class ViewController: UIViewController, Storyboarded {

    weak var coordinator: MainCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    // MARK: - Private Section -

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var footwearLabel: UILabel!
    @IBOutlet private weak var observationsLabel: UILabel!

    @IBAction private func takePicture(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        present(picker, animated: true)
    }

    @IBAction private func choosePicture(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }


    private func updateClassifications(for image: UIImage) {
        observationsLabel.text = "Analyzing the image..."

        guard let ciImage = CIImage(image: image), let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
            fatalError("Can't create CIImage from \(image)")
        }

        // Classify the images
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            let request = VNClassifyImageRequest()
            do {
                try handler.perform([request])
                self.process(request: request)
            } catch {
                print("Failed to classify the image: \(error.localizedDescription)")
            }
        }
    }


    private func process(request: VNRequest) {
        guard let observations = request.results as? [VNClassificationObservation] else {
            return
        }

        let categories = observations.filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
        let searchTerms = observations.filter { $0.hasMinimumPrecision(0.01, forRecall: 0.7) }

        let footwearTerms: Set = ["footwear", "shoes", "sneaker"]
        var isFootwear = false
        for category in categories {
            if footwearTerms.contains(category.identifier) {
                isFootwear = true
            }
        }

        let categoriesText = categories.reduce("Categories for precision: 0.9 \n") { (result, observation) -> String in
            return result + "Category: \(observation.identifier). Confidence: \(observation.confidence) \n"
        }

        let searchTermsText = searchTerms.reduce("\nSearch Term for recall: 0.7 \n") { (result, observation) -> String in
            return result + "Term: \(observation.identifier). Confidence: \(observation.confidence) \n"
        }

        DispatchQueue.main.async {
            self.footwearLabel.isHidden = false
            self.footwearLabel.text = isFootwear ? "Footwear" : "NOT Footwear"
            self.footwearLabel.textColor = isFootwear ? .green : .red
            self.observationsLabel.text = categoriesText + searchTermsText
        }
    }
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        guard let uiImage = info[.originalImage] as? UIImage else {
            fatalError("Unable to get UIImage from image picker")
        }

        imageView.image = uiImage

        updateClassifications(for: uiImage)
    }
}
