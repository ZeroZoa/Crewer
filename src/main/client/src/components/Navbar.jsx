import React from "react";
import { useNavigate } from "react-router-dom";
import { ChevronLeft, LogIn, UserPlus, LogOut } from "lucide-react"; // 아이콘 추가

function Navbar() {
    const navigate = useNavigate();

    const handleBack = () => {
        navigate(-1);
    };

    const handleLogout = () => {
        localStorage.removeItem("token");
        sessionStorage.clear();

        alert("로그아웃 되었습니다.");

        setTimeout(() => {
            window.location.href = "/"; // ✅ navigate() 대신 직접 페이지 이동
        }, 100);
    };

    const isLoggedIn = !!localStorage.getItem("token");

    return (
        <nav className="bg-white text-[#9cb4cd] h-16 px-6 flex justify-between items-center border-b border-gray-300
                        fixed top-0 left-0 right-0 z-50">
            {/* 왼쪽: 뒤로가기 버튼 */}
            <button onClick={handleBack} className="hover:text-[#b3c7de] transition">
                <ChevronLeft className="w-9 h-9" />
            </button>

            {/* 프로젝트명 (클릭하면 인덱스 페이지로 이동) */}
            <button
                onClick={() => navigate("/")}
                className="text-3xl font-semibold text-[#9cb4cd] hover:text-[#b3c7de] transition"
                style={{ fontFamily: "MyCustomFont" }}
            >
                Crewer
            </button>

            {/* 오른쪽: 로그인/회원가입 또는 로그아웃 */}
            <div className="flex space-x-5">
                {isLoggedIn ? (
                    <button onClick={handleLogout} className="hover:text-[#b3c7de] transition">
                        <LogOut className="w-7 h-7" />
                    </button>
                ) : (
                    <>
                        <button onClick={() => navigate("/login")} className="hover:text-[#b3c7de] transition">
                            <LogIn className="w-7 h-7" />
                        </button>
                        <button onClick={() => navigate("/register")} className="hover:text-[#b3c7de] transition">
                            <UserPlus className="w-7 h-7" />
                        </button>
                    </>
                )}
            </div>
        </nav>
    );
}

export default Navbar;