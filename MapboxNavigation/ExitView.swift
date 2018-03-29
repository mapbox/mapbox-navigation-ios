//
//  ExitView.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 3/23/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import UIKit

class ExitView: UIView {
    static let exitImage = UIImage(named: "exit", in: .mapboxNavigation, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)

    lazy var imageView: UIImageView = {
        let view = UIImageView(image: ExitView.exitImage)
        view.tintColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var exitNumberLabel: UILabel = {
        let label: UILabel = .forAutoLayout()
        label.text = exitText
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        return label
    }()

    var exitText: String? {
        didSet {
            exitNumberLabel.text = exitText
            invalidateIntrinsicContentSize()
        }
    }
    var pointSize: CGFloat?

    
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: 100, height: 50)
//    }
//    
    convenience init(pointSize: CGFloat) {
        self.init(frame: .zero)
        self.pointSize = pointSize
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .darkGray
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        setupViews()
        setupConstraints()
    }
    func setupViews() {
        [imageView, exitNumberLabel].forEach(addSubview(_:))
    }
    func setupConstraints() {
        let imageTop = imageView.topAnchor.constraint(equalTo: topAnchor, constant: 2)
        let imageBottom = imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        let imageLeading = imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        let imageAspect = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: imageView.image?.size.aspectRatio ?? 1.0)
        let imageCenterY = imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        let height = heightAnchor.constraint(equalToConstant: pointSize! * 1.2)
        let imageLabelSpacing = imageView.trailingAnchor.constraint(equalTo: exitNumberLabel.leadingAnchor, constant: -8)
        
        let labelCenterY = exitNumberLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        let labelTrailing = trailingAnchor.constraint(equalTo: exitNumberLabel.trailingAnchor, constant: 8)
        
        
        let constraints = [imageTop, imageBottom, imageCenterY, imageLeading,imageAspect, height, //imageLeading, imageCenterY, imageWidth,
                           imageLabelSpacing, labelCenterY, labelTrailing]
        addConstraints(constraints)
    }
}
