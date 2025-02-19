import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import { LoadScriptNext } from "@react-google-maps/api"; // ✅ LoadScript 대신 LoadScriptNext 사용

import SignupPage from "./pages/SignupPage";
import LoginPage from "./pages/LoginPage";
import FeedListPage from "./pages/FeedListPage";
import FeedDetailPage from "./pages/FeedDetailPage";
import FeedCreatePage from "./pages/FeedCreatePage";
import FeedEditPage from "./pages/FeedEditPage";
import ChatRoomListPage from "./pages/ChatRoomListPage";
import Navbar from "./components/Navbar";
import BottomNavBar from "./components/BottomNavBar";
import MyProfilePage from "./pages/MyProfilePage";
import MyFeedsPage from "./pages/MyFeedsPage";
import MyLikedFeedsPage from "./pages/MyLikedFeedsPage";
import MapPage from "./pages/MapPage";

function App() {
    const [apiKey, setApiKey] = useState("");

    useEffect(() => {
        // Spring Boot에서 Google Maps API Key 가져오기
        fetch("http://localhost:8080/api/config/google-maps-key")
            .then(response => response.text())
            .then(key => {setApiKey(key.trim());})
            .catch(error => console.error("❌ Google Maps API Key 불러오기 실패:", error));
    }, []);

    return (
        apiKey ? (
            <LoadScriptNext googleMapsApiKey={apiKey} preventGoogleFonts={true}> {/* ✅ LoadScriptNext 사용 */}
                <Router>
                    <div>
                        <Navbar />
                        <div>
                            <Routes>
                                <Route path="/register" element={<SignupPage />} />
                                <Route path="/login" element={<LoginPage />} />
                                <Route path="/" element={<FeedListPage />} />
                                <Route path="/feeds/:id" element={<FeedDetailPage />} />
                                <Route path="/feeds/create" element={<FeedCreatePage />} />
                                <Route path="/feeds/:id/edit" element={<FeedEditPage />} />
                                <Route path="/chat/room" element={<ChatRoomListPage />} />
                                <Route path="/profile/me" element={<MyProfilePage />} />
                                <Route path="/profile/me/feeds" element={<MyFeedsPage />} />
                                <Route path="/profile/me/liked-feeds" element={<MyLikedFeedsPage />} />
                                <Route path="/map" element={<MapPage />} />
                            </Routes>
                        </div>
                        <BottomNavBar />
                    </div>
                </Router>
            </LoadScriptNext>
        ) : (
            <p className="text-center text-gray-500 mt-10">Google Maps API Key를 불러오는 중...</p>
        )
    );
}

export default App;