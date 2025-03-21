import { Navigate } from "react-router-dom";

const ProtectedRoute = ({ children }) => {
    const token = localStorage.getItem("token");

    // 토큰이 없으면 → 알림 후 로그인 페이지로 이동
    if (!token) {
        alert("로그인이 필요한 페이지입니다."); // ✅ 알림 추가
        return <Navigate to="/login" replace />;
    }

    return children;
};

export default ProtectedRoute;