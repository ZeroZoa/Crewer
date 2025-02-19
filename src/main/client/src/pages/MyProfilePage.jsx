import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { ChevronRight } from "lucide-react"; // ✅ ChevronRight 아이콘 추가

const MyProfilePage = () => {
    const [profile, setProfile] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const navigate = useNavigate();

    useEffect(() => {
        const token = localStorage.getItem("token");
        if (!token) {
            alert("로그인이 필요합니다.");
            navigate("/login");
            return;
        }

        const fetchProfile = async () => {
            try {
                const response = await axios.get("http://localhost:8080/profile/me", {
                    headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
                });

                if (response.status !== 200) {
                    throw new Error("프로필 정보를 가져올 수 없습니다.");
                }

                setProfile(response.data);
            } catch (error) {
                if (error.response && error.response.status === 401) {
                    alert(error.response.data || "로그인이 필요합니다.");
                    navigate("/login");
                } else {
                    setError(error.message);
                }
            } finally {
                setLoading(false);
            }
        };

        fetchProfile();
    }, [navigate]);

    if (loading) return <p className="text-center mt-5 text-gray-500">로딩 중...</p>;
    if (error) return <p className="text-center mt-5 text-red-500">{error}</p>;

    return (
        <div className="min-h-screen flex flex-col items-center w-full bg-gray-100">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl flex-grow">
                {/* 프로필 정보 */}
                <div className="relative flex items-center space-x-6">
                    {profile && (
                        <img
                            src={profile.avatarUrl}
                            alt="Profile"
                            className="w-28 h-28 rounded-full border shadow-lg"
                        />
                    )}
                    <h1 className="text-2xl font-bold">{profile?.nickname}</h1>
                </div>

                <hr className="border-t-[1px] border-[#9cb4cd] mt-6 my-1"/>

                {/* 나의 피드 버튼 */}
                <div
                    className="flex items-center justify-between p-4  rounded-lg cursor-pointer hover:bg-gray-300 transition"
                    onClick={() => navigate("/profile/me/feeds")}
                >
                    <h2 className="text-xl font-bold">나의 피드</h2>
                    <ChevronRight className="w-8 h-8 text-gray-700"/> {/* ✅ ChevronRight 아이콘 추가 */}
                </div>

                <hr className="border-t-[1px] border-[#9cb4cd] my-1"/>

                <div
                    className="flex items-center justify-between p-4  rounded-lg cursor-pointer hover:bg-gray-300 transition"
                    onClick={() => navigate("/profile/me/liked-feeds")}
                >
                    <h2 className="text-xl font-bold">좋아요한 피드</h2>
                    <ChevronRight className="w-8 h-8 text-gray-700"/> {/* ✅ ChevronRight 아이콘 추가 */}
                </div>

                <hr className="border-t-[1px] border-[#9cb4cd] my-1"/>
            </div>
        </div>
    );
};

export default MyProfilePage;