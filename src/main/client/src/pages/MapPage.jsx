import React, { useState, useEffect, useRef } from "react";
import { GoogleMap, useJsApiLoader, Marker } from "@react-google-maps/api";

const MapPage = () => {
    const { isLoaded } = useJsApiLoader({
        googleMapsApiKey: "YOUR_GOOGLE_MAPS_API_KEY",
    });

    const [mapId, setMapId] = useState(null);
    const mapRef = useRef(null);
    const markerRef = useRef(null);
    const [userLocation, setUserLocation] = useState(null);
    const [heading, setHeading] = useState(0);

    // ✅ 1. Google Maps API 키 불러오기
    useEffect(() => {
        fetch("http://localhost:8080/api/config/google-maps-map-id")
            .then(response => response.text())
            .then(id => setMapId(id.trim()))
            .catch(error => console.error("❌ Google Maps Map ID 불러오기 실패:", error));
    }, []);

    // ✅ 2. 위치 추적 및 지도 이동
    useEffect(() => {
        if (navigator.geolocation) {
            const watchId = navigator.geolocation.watchPosition(
                (position) => {
                    const newLocation = {
                        lat: position.coords.latitude,
                        lng: position.coords.longitude,
                    };

                    setUserLocation(newLocation);
                    if (position.coords.heading !== null) {
                        setHeading(position.coords.heading);
                    }

                    if (mapRef.current) {
                        mapRef.current.panTo(newLocation);
                    }
                },
                (error) => console.error("위치 정보를 가져올 수 없습니다:", error),
                { enableHighAccuracy: true, maximumAge: 0 }
            );

            return () => {
                navigator.geolocation.clearWatch(watchId);
            };
        }
    }, []);

    // ✅ 3. heading 값이 변경될 때마다 마커 업데이트
    useEffect(() => {
        if (isLoaded && window.google && window.google.maps && mapRef.current) {
            if (markerRef.current) {
                markerRef.current.setPosition(userLocation);
            } else if (userLocation) {
                markerRef.current = new window.google.maps.Marker({
                    position: userLocation,
                    map: mapRef.current,
                    title: "내 위치",
                });
            }
        }
    }, [isLoaded, heading, userLocation]);

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
                    zoom={17}
                    mapId={mapId}
                    onLoad={handleMapLoad}
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