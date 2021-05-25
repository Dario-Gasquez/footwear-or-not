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
    @IBOutlet private weak var modelSelectionControl: UISegmentedControl!


    private lazy var mobileNetRequest: VNCoreMLRequest = {
        return generateCoreMLRequest(forModel: MobileNet().model)

    }()


    private lazy var resnet50Request: VNCoreMLRequest = {
        return generateCoreMLRequest(forModel: Resnet50().model)

    }()


    private func generateCoreMLRequest(forModel mlModel: MLModel) -> VNCoreMLRequest {
        do {
            let model = try VNCoreMLModel(for: mlModel)
            let coreMLRequest = VNCoreMLRequest(model: model)
            coreMLRequest.imageCropAndScaleOption = .centerCrop
            return coreMLRequest
        } catch {
            fatalError("Failed to load ML model: \(error)")
        }

    }

    /// Holds the request for the different model types: Vision, MobileNet, Resnet50, etcetera
    private lazy var requests: [VNRequest] = [VNClassifyImageRequest(), mobileNetRequest, resnet50Request]

    @IBAction func didSelectNewModel(_ sender: UISegmentedControl) {
        guard let image = imageView.image else {
            observationsLabel.text = "Please, choose an image first.."
            return
        }

        updateClassifications(for: image)
    }


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

        guard modelSelectionControl.selectedSegmentIndex < requests.count else {
            print(">>>> WARNING: selected model index too high <<<<<<")
            observationsLabel.text = "Sorry, selected model is not available yet"
            return
        }

        let request = requests[modelSelectionControl.selectedSegmentIndex]

        // Classify the images
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([request])
                self.process(request: request)
            } catch {
                print("Failed to classify the image: \(error.localizedDescription)")
            }
        }
    }


    private func process(request: VNRequest, error: Error? = nil) {
        guard let observations = request.results as? [VNClassificationObservation] else {
            return
        }

        let categoriesAbove90 = observations.filter { $0.confidence > 0.9 } // { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
        let highestFiveCategories = observations.prefix(5)

        let footwearTerms: Set = ["footwear", "shoes", "sneaker", "running shoe"]
        var isFootwear = false
        for category in categoriesAbove90 {
            if footwearTerms.contains(category.identifier.lowercased()) {
                isFootwear = true
                break
            }
        }

        let categoriesText = highestFiveCategories.reduce("Highest 5 categories\n") { (result, observation) -> String in
            return result + "Category: \(observation.identifier). Confidence: \(observation.confidence) \n"
        }

        DispatchQueue.main.async {
            self.footwearLabel.isHidden = false
            self.footwearLabel.text = isFootwear ? "Footwear" : "NOT Footwear"
            self.footwearLabel.textColor = isFootwear ? .green : .red
            self.observationsLabel.text = categoriesText
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
