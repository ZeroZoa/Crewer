import React from "react";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import ProtectedRoute from "./components/ProtectedRoute";

import NotFoundPage from "./pages/NotFoundPage";
import SignupPage from "./pages/SignupPage";
import LoginPage from "./pages/LoginPage";
import FeedListPage from "./pages/FeedListPage";
import FeedDetailPage from "./pages/FeedDetailPage";
import GroupFeedDetailPage from "./pages/GroupFeedDetailPage";
import FeedCreatePage from "./pages/FeedCreatePage";
import GroupFeedCreatePage from "./pages/GroupFeedCreatePage";
import FeedEditPage from "./pages/FeedEditPage";
import GroupFeedEditPage from "./pages/GroupFeedEditPage";
import ChatRoomListPage from "./pages/ChatRoomListPage";
import ChatRoomPage from "./pages/ChatRoomPage";
import Navbar from "./components/Navbar";
import BottomNavBar from "./components/BottomNavBar";
import MyProfilePage from "./pages/MyProfilePage";
import MyFeedPage from "./pages/MyFeedPage";
import MyLikedFeedPage from "./pages/MyLikedFeedPage";
import MapPage from "./pages/MapPage";

function App() {
    return (
        <Router>
            <Navbar />
            <Routes>
                {/* 로그인 없이 접근 가능한 라우트 */}
                <Route path="/" element={<FeedListPage />} />
                <Route path="/register" element={<SignupPage />} />
                <Route path="/login" element={<LoginPage />} />
                <Route path="/feeds/:id" element={<FeedDetailPage />} />
                <Route path="/groupfeeds/:id" element={<GroupFeedDetailPage />} />
                <Route path="*" element={<NotFoundPage />} />

                {/* 로그인 필요 라우트 - ProtectedRoute로 감싸기 */}
                <Route
                    path="/feeds/create"
                    element={
                        <ProtectedRoute>
                            <FeedCreatePage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/groupfeeds/create"
                    element={
                        <ProtectedRoute>
                            <GroupFeedCreatePage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/feeds/:id/edit"
                    element={
                        <ProtectedRoute>
                            <FeedEditPage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/groupfeeds/:id/edit"
                    element={
                        <ProtectedRoute>
                            <GroupFeedEditPage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/chat"
                    element={
                        <ProtectedRoute>
                            <ChatRoomListPage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/chat/:chatRoomId"
                    element={
                        <ProtectedRoute>
                            <ChatRoomPage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/profile/me"
                    element={
                        <ProtectedRoute>
                            <MyProfilePage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/profile/me/feeds"
                    element={
                        <ProtectedRoute>
                            <MyFeedPage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/profile/me/liked-feeds"
                    element={
                        <ProtectedRoute>
                            <MyLikedFeedPage />
                        </ProtectedRoute>
                    }
                />
                <Route
                    path="/map"
                    element={
                        <ProtectedRoute>
                            <MapPage />
                        </ProtectedRoute>
                    }
                />
            </Routes>
            <BottomNavBar />
        </Router>
    );
}

export default App;