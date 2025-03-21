import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { Heart, MessageCircle } from "lucide-react"; // ✅ 좋아요 및 댓글 아이콘 추가

const MyLikedFeedPage = () => {
    const [feeds, setFeeds] = useState([]); // ✅ 좋아요한 피드 리스트
    const [loading, setLoading] = useState(true); // ✅ 로딩 상태 관리
    const [error, setError] = useState(null); // ✅ 에러 상태 관리
    const navigate = useNavigate();

    useEffect(() => {
        // ✅ API 호출하여 사용자가 좋아요한 피드를 가져옴
        const fetchLikedFeeds = async () => {
            try {
                const response = await axios.get("http://localhost:8080/profile/me/liked-feeds", {
                    headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
                });
                // ✅ API 응답이 피드 리스트를 바로 반환하는 경우
                setFeeds(response.data);
            } catch (error) {
                console.error("좋아요한 피드 불러오기 실패:", error);
                setError("좋아요한 피드를 불러올 수 없습니다.");
            } finally {
                setLoading(false);
            }
        };

        fetchLikedFeeds();
    }, []);

    if (loading) return <p className="text-center mt-5 text-gray-500">로딩 중...</p>;
    if (error) return <p className="text-center mt-5 text-red-500">{error}</p>;

    return (
        <div className="h-screen flex flex-col items-center w-full mt-16">
            <div className="bg-white shadow-lg rounded-lg p-6 w-full max-w-3xl h-full">
                <h1 className="text-3xl font-bold text-[#9cb4cd] mb-6">내가 좋아요한 피드</h1> {/* ✅ 제목 수정 */}
                <div className="mt-4 space-y-2">
                    {feeds.length > 0 ? (
                        feeds.map((feed) => (
                            <div
                                key={feed.id}
                                className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-200 shadow-2xl cursor-pointer transition relative mb-2"
                                onClick={() =>
                                    navigate(feed.chatRoomId ? `/groupfeeds/${feed.id}` : `/feeds/${feed.id}`)
                                }
                            >
                                <div className="flex justify-between items-center">
                                    <h3 className="text-lg font-semibold">{feed.title}</h3> {/* ✅ 제목 표시 */}
                                    <div className="flex items-center space-x-3">
                                        <div className="flex items-center space-x-1">
                                            <Heart className="w-5 h-5 text-red-500" />
                                            <span className="text-gray-700">
                        {feed.chatRoomId
                            ? (feed.groupLikesCount || 0)
                            : (feed.likesCount || 0)}
                      </span>
                                        </div>
                                        <div className="flex items-center space-x-1">
                                            <MessageCircle className="w-5 h-5 text-blue-500" />
                                            <span className="text-gray-700">
                        {feed.chatRoomId
                            ? (feed.groupCommentsCount || 0)
                            : (feed.commentsCount || 0)}
                      </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))
                    ) : (
                        <p className="text-gray-500 text-center">좋아요한 피드가 없습니다.</p>
                    )}
                </div>
            </div>
        </div>
    );
};

export default MyLikedFeedPage;