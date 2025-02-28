import React, { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Plus, Heart, MessageCircle } from "lucide-react"; // ✅ 댓글 아이콘 추가

const FeedListPage = () => {
    const [feeds, setFeeds] = useState([]);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchFeeds = async () => {
            try {
                const response = await fetch("http://localhost:8080/feeds");
                if (response.ok) {
                    let data = await response.json();

                    // ✅ 백엔드에서 content 필드만 추출
                    let feedList = data.content || [];

                    // ✅ createdAt 기준 최신순 정렬
                    feedList.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

                    setFeeds(feedList);
                } else {
                    console.error("Failed to fetch feeds");
                }
            } catch (error) {
                console.error("Error fetching feeds:", error);
            }
        };

        fetchFeeds();
    }, []);

    //feed 제목 제한 "30글자 제한 이후는 ..."
    const truncateTitle = (title) => {
        return title.length > 30 ? title.substring(0, 30) + "..." : title;
    };

    //날짜 포맷 함수
    const formatDate = (date) => {
        const options = { year: "numeric", month: "long", day: "numeric" };
        return new Date(date).toLocaleDateString("ko-KR", options);
    };

    return (
        <div className="min-h-screen flex flex-col items-center w-full">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl h-full flex-grow mb-10">
                {feeds.map((feed, index) => (
                    <div
                        key={feed.id || `feed-${index}`} // ✅ ID가 없으면 index 사용
                        className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-200 shadow-2xl cursor-pointer transition relative mb-3"
                        onClick={() => navigate(`/feeds/${feed.id}`)}
                    >
                        <div className="flex flex-col items-start">
                            <h2 className="text-2xl font-bold">{truncateTitle(feed.title)}</h2>
                            <p className="text-gray-600 text-sm">
                                {formatDate(feed.createdAt)} · {feed.authorNickname || "알 수 없음"}
                            </p>
                        </div>

                        {/* ✅ 좋아요 & 댓글 수 추가 */}
                        <div className="absolute bottom-3 right-4 flex items-center space-x-3">
                            <div className="flex items-center space-x-1">
                                <Heart className="w-4 h-4 text-red-500" />
                                <span className="text-gray-700">{feed.likesCount || 0}</span>
                            </div>
                            <div className="flex items-center space-x-1">
                                <MessageCircle className="w-4 h-4 text-blue-500" />
                                <span className="text-gray-700">{feed.commentsCount || 0}</span>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* 플로팅 버튼 */}
            <Link
                to="/feeds/create"
                className="fixed bottom-20 right-6 border-4 border-[#9cb4cd] bg-white text-[#9cb4cd] w-16 h-16 rounded-full flex items-center justify-center shadow-xl hover:bg-[#9cb4cd] hover:text-white focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
            >
                <Plus className="w-9 h-9" />
            </Link>
        </div>
    );
};

export default FeedListPage;