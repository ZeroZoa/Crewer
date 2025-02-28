import React, { useState, useEffect, useRef } from "react";
import { GoogleMap, useJsApiLoader, Marker } from "@react-google-maps/api";

const MapPage = () => {
    const { isLoaded } = useJsApiLoader({
        googleMapsApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
    });

    const [mapId, setMapId] = useState(null);
    const mapRef = useRef(null);
    const [userLocation, setUserLocation] = useState(null);
    const markerRef = useRef(null);

    // ✅ 페이지 진입 시 스크롤 막기, 나갈 때 복구
    useEffect(() => {
        document.body.style.overflow = "hidden"; // 스크롤 막기
        return () => {
            document.body.style.overflow = "auto"; // 페이지 떠날 때 복구
        };
    }, []);

    // ✅ Google Maps API 키 불러오기
    useEffect(() => {
        fetch("http://localhost:8080/api/config/google-maps-map-id")
            .then(response => response.text())
            .then(id => setMapId(id.trim()))
            .catch(error => console.error("❌ Google Maps mapId 불러오기 실패:", error));
    }, []);

    // ✅ 1. 초기 위치 가져오기 (새로고침해도 내 위치 보이게 설정)
    useEffect(() => {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const newLocation = {
                        lat: position.coords.latitude,
                        lng: position.coords.longitude,
                    };
                    setUserLocation(newLocation);
                    if (mapRef.current) {
                        mapRef.current.panTo(newLocation);
                    }
                },
                (error) => console.error("❌ 초기 위치 가져오기 실패:", error),
                { enableHighAccuracy: true, timeout: 5000 }
            );
        }
    }, []);

    // ✅ 2. 실시간 위치 추적 (위치 변경 시 지도 & 마커 업데이트)
    useEffect(() => {
        if (navigator.geolocation) {
            const watchId = navigator.geolocation.watchPosition(
                (position) => {
                    const newLocation = {
                        lat: position.coords.latitude,
                        lng: position.coords.longitude,
                    };
                    setUserLocation(newLocation);
                    if (mapRef.current) {
                        mapRef.current.panTo(newLocation);
                    }
                },
                (error) => console.error("❌ 위치 추적 실패:", error),
                { enableHighAccuracy: true, maximumAge: 5000, timeout: 10000 }
            );

            return () => navigator.geolocation.clearWatch(watchId);
        }
    }, []);

    // ✅ 3. 마커 업데이트 (새로고침 후에도 정상 표시)
    useEffect(() => {
        if (isLoaded && userLocation && window.google && window.google.maps && mapRef.current) {
            if (markerRef.current) {
                markerRef.current.setPosition(userLocation);
            } else {
                markerRef.current = new window.google.maps.Marker({
                    position: userLocation,
                    map: mapRef.current,
                    title: "내 위치",
                });
            }
        }
    }, [isLoaded, userLocation]);

    const handleMapLoad = (map) => {
        mapRef.current = map;
    };

    const defaultCenter = { lat: 37.5665, lng: 126.9780 };

    return (
        <div className="w-full h-screen">
            {isLoaded && mapId ? (
                <GoogleMap
                    mapContainerStyle={{ width: "100%", height: "100%" }}
                    center={userLocation || defaultCenter}
                    zoom={18}
                    mapId={mapId}
                    onLoad={handleMapLoad}
                    options={{
                        disableDefaultUI: true, // ✅ 모든 기본 UI 요소 제거
                        zoomControl: true, // ✅ 줌 컨트롤 유지
                    }}
                >
                    {userLocation && <Marker position={userLocation} title="내 위치" />}
                </GoogleMap>
            ) : (
                <p className="text-gray-500 flex items-center justify-center w-screen h-screen">
                    지도를 불러오는 중...
                </p>
            )}
        </div>
    );
};

export default MapPage;