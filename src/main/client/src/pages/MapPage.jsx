import React, { useEffect, useState, useRef } from "react";
import { GoogleMap, useJsApiLoader, Marker } from "@react-google-maps/api";

const MapComponent = ({ apiKey, mapId, userLocation, defaultCenter, handleMapLoad }) => {
    // useJsApiLoader는 항상 동일한 옵션으로 호출됨
    const { isLoaded } = useJsApiLoader({
        googleMapsApiKey: apiKey,
        id: "google-map-script",
        libraries: ["maps"],
    });

    if (!isLoaded) {
        return (
            <p className="text-gray-500 flex items-center justify-center w-screen h-screen">
                지도를 불러오는 중...
            </p>
        );
    }

    return (
        <GoogleMap
            mapContainerStyle={{ width: "100%", height: "86%" }}
            center={userLocation || defaultCenter}
            zoom={18}
            mapId={mapId}
            onLoad={handleMapLoad}
            options={{
                disableDefaultUI: true,
                zoomControl: true,
            }}
        >
            {userLocation && <Marker position={userLocation} title="내 위치" />}
        </GoogleMap>
    );
};

const MapPage = () => {
    const [apiKey, setApiKey] = useState(null); // API 키를 저장 (초기 null)
    const [mapId, setMapId] = useState(null);     // Map ID 저장
    const mapRef = useRef(null);
    const [userLocation, setUserLocation] = useState(null);
    const defaultCenter = { lat: 37.5665, lng: 126.9780 };

    // 수정: 페이지 스크롤 락 효과 추가 (컴포넌트 마운트 시 스크롤 비활성화)
    useEffect(() => {
        document.body.style.overflow = "hidden"; // 스크롤 락
        return () => {
            document.body.style.overflow = "unset"; // 컴포넌트 언마운트 시 원래 상태 복구
        };
    }, []);

    // 백엔드에서 Google Maps API 키와 Map ID를 가져오기
    useEffect(() => {
        const fetchApiKeys = async () => {
            try {
                const keyResponse = await fetch("http://localhost:8080/api/config/google-maps-key");
                const key = await keyResponse.text();
                setApiKey(key.trim() || null); // 키가 없으면 null 유지

                const mapIdResponse = await fetch("http://localhost:8080/api/config/google-maps-map-id");
                const id = await mapIdResponse.text();
                setMapId(id.trim());
            } catch (error) {
                console.error("Google Maps API Key 불러오기 실패:", error);
            }
        };

        fetchApiKeys();
    }, []);

    // 사용자의 초기 위치 가져오기 (실시간 위치 업데이트 가능)
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
                (error) => console.error("초기 위치 가져오기 실패:", error),
                { enableHighAccuracy: true, timeout: 5000 }
            );
        }
    }, []);

    // 지도 로드 시 mapRef에 저장
    const handleMapLoad = (map) => {
        mapRef.current = map;
    };

    // API 키와 mapId가 준비되지 않으면 로딩 화면을 보여줌
    if (!apiKey || !mapId) {
        return (
            <p className="text-gray-500 flex items-center justify-center w-screen h-screen">
                Google Maps API Key를 불러오는 중...
            </p>
        );
    }

    return (
        <div className="w-full h-screen mt-16">
            <MapComponent
                apiKey={apiKey}
                mapId={mapId}
                userLocation={userLocation}
                defaultCenter={defaultCenter}
                handleMapLoad={handleMapLoad}
            />
        </div>
    );
};

export default MapPage;