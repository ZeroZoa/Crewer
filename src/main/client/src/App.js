import React from "react";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import SignupPage from "./pages/SignupPage";
import LoginPage from "./pages/LoginPage"; // 회원가입 페이지 컴포넌트 가져오기
import FeedListPage from "./pages/FeedListPage";
import FeedDetailPage from "./pages/FeedDetailPage";
import FeedCreatePage from "./pages/FeedCreatePage";
import FeedEditPage from "./pages/FeedEditPage";
import Navbar from "./components/Navbar"; // 네비게이션 바 컴포넌트 추가
import BottomNavBar from "./components/BottomNavBar";

function App() {
    return (
        <Router>
            <div>
                {/* 네비게이션 바 */}
                <Navbar />
                <div className="p-4">
                    <Routes>
                        {/* 회원가입 페이지 */}
                        <Route path="/register" element={<SignupPage />} />
                        {/* 로그인 페이지 */}
                        <Route path="/login" element={<LoginPage />} />
                        {/* 피드 리스트 페이지 */}
                        <Route path="/" element={<FeedListPage />} />
                        {/* 피드 상세 페이지 */}
                        <Route path="/feeds/:id" element={<FeedDetailPage />} />
                        {/* 피드 생성 페이지 */}
                        <Route path="/feeds/create" element={<FeedCreatePage />} />
                        {/* 피드 수정 페이지 */}
                        <Route path="/feeds/:id/edit" element={<FeedEditPage />} />
                    </Routes>
                </div>
                <BottomNavBar />
            </div>
        </Router>
    );
}

export default App;