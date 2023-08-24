//
//  ViewController.swift
//  Mission0823
//
//  Created by LOUIE MAC on 2023/08/23.
//

import UIKit
import MapKit
import SnapKit
import CoreLocation
// MARK: - import CoreLocation -> Declare CLLocationManater()

final class ViewController: UIViewController {
    
    
    let locationManager = CLLocationManager()
    let mapView = MKMapView()
    var theaterList = TheaterList()
    var locationArray:[MKPointAnnotation] = []
    let locationButton: UIButton = {
       let btn = UIButton()
        btn.setImage(UIImage(systemName: "location.circle.fill"), for: .normal)
        btn.tintColor = UIColor.black
        return btn
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkLocationAuthorization()
    }
    
    
    private func setupUI() {
        view.addSubview(mapView)
        view.addSubview(locationButton)
        locationManager.delegate = self
        setConstraints()
        setNavigationController()
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
    }
    
    private func setNavigationController() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .clear
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.standardAppearance = appearance
        navigationItem.rightBarButtonItem =
        UIBarButtonItem(title: "Filter",
                        style: .plain,
                        target: self,
                        action: #selector(showTheatersActionSheet))
        navigationController?.navigationBar.tintColor = .systemPink
    }
    
    // MARK: - 전체 영화관표시
    private func setInitialAnnotation() {
        mapView.removeAnnotations(locationArray)
        for theater in theaterList.mapAnnotations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            locationArray.append(annotation)
        }
        mapView.addAnnotations(locationArray)
    }
    
    
    // MARK: - 지도 중심 기반으로 보여질 범위를 담당하능 기능 함수
    private func setRegionWithAnnotoation(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 400, longitudinalMeters: 400)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Authorization Check Only // 권한이 결정이 되지 않았을때만 Alert 을 띄움.
    private func checkLocationAuthorization() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                
                let auth: CLAuthorizationStatus
                
                if #available(iOS 14.0, *) {
                    auth = self.locationManager.authorizationStatus
                } else {
                    auth = CLLocationManager.authorizationStatus()
                }
                print(auth)
                DispatchQueue.main.async {
                    self.checkCurrentLocationAuthrization(status: auth)
                }
            } else {
                self.showLocationPermissionAlert()
            }
        }
    }
    
    
    // MARK: - Location 권한 설정 요청 Alert
    @objc private func showLocationPermissionAlert() {
        
        let alert = UIAlertController(title: "위치 정보가 필요해요.",
                                      message: """
        위치 정보를 사용할 수 있도록
        기기의 '설정 > 개인정보 보호 및 보안' 에서
        '위치 서비스'를 켜주세요.
        """,
                                      preferredStyle: .alert)
        
        let success = UIAlertAction(title: "설정으로 갈래", style: .default) { _ in
            print("설정이동")
            if let appSetting = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSetting)
            }
        }
        
        let deny = UIAlertAction(title: "지금은 안할래", style: .cancel)
        
        alert.addAction(success)
        alert.addAction(deny)
        
        present(alert, animated: true) { print("완료되었음") }
    }
    
    // MARK: - All Theater Action Sheet
    @objc private func showTheatersActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for target in Set(theaterList.mapAnnotations.map({ $0.type })) {
            let action = UIAlertAction(title: target, style: .default) { [weak self] _ in
                
                self?.mapView.removeAnnotations(self?.mapView.annotations ?? [])
                
                let annotationsToAdd = self?.theaterList.mapAnnotations.filter { $0.type == target } ?? []
                let newAnnotation = annotationsToAdd.map { theater in
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
                    annotation.title = theater.type
                    return annotation
                }
                
                self?.locationArray.append(contentsOf: newAnnotation)
                self?.mapView.addAnnotations(newAnnotation)
                if let region = newAnnotation.first?.coordinate {
                    self?.setRegionWithAnnotoation(center: region)
                }
            }
            actionSheet.addAction(action)
        }
        
        let showAllAction = UIAlertAction(title: "전체보기", style: .default) { [weak self] _ in
            self?.setInitialAnnotation()
        }
        
        let cancelAction = UIAlertAction(title: "그만보기", style: .cancel, handler: nil)
        
        actionSheet.addAction(showAllAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - 위에서 CLAuthorizationStatus의 결과를 받아왔다는 전제 하에.
    private func checkCurrentLocationAuthrization(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("restricted.")
        case .denied:
            setAnnotationWhenDenied()
            showLocationPermissionAlert()
        case .authorizedAlways:
            setInitialAnnotation()
        case .authorizedWhenInUse:
            setInitialAnnotation()
        case .authorized:
            print("authorized")
        @unknown default:
            print("Error")
        }
    }
    
    // MARK: - Deny 했을때 캠퍼스로 세팅
    private func setAnnotationWhenDenied() {
        let campus = CLLocationCoordinate2D(latitude: 37.517829, longitude: 126.886270)
        let annotation = MKPointAnnotation()
        annotation.coordinate = campus
        mapView.addAnnotation(annotation)
        setRegionWithAnnotoation(center: campus)
    }
    
    // MARK: - 위치 버튼 탭 했을때의 동작
    @objc private func locationButtonTapped() {
        if locationManager.authorizationStatus == .denied {
            showLocationPermissionAlert()
        } else {
            setInitialAnnotation()
        }
    }
    
    // MARK: - Constraints()
    private func setConstraints() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        locationButton.snp.makeConstraints { make in
            make.trailing.equalTo(view).offset(-35)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-35)
            make.size.equalTo(50)
        }
    }
}


extension ViewController: CLLocationManagerDelegate {
    
    // MARK: - 사용자의 위치를 가지고 온 경우
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = locations.last?.coordinate {
            setRegionWithAnnotoation(center: coordinate)
        }
    }
    
    // MARK: - 사용자의 위치를 못가져오지 못하거나 or 권한이 꺼져있어서 위치가 파악이 안될경우 이 메서드가 감지함.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showLocationPermissionAlert()
    }
    
    // MARK: - upTo iOS14 -> 사용자의 권한 상태가 '바뀔때' 호출됨 + case: 허용->거부 + 권한이 변경된것만 감지하지 어떤 케이스인지는 모름
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

