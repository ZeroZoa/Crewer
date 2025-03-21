// 주석: FeedListPage 컴포넌트 (수정: key 생성 시 index를 추가하여 고유키 생성)
import React, { useEffect, useState, useRef, useCallback } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Plus, X, Heart, MessageCircle, User, Users } from "lucide-react"; // 댓글 아이콘 추가

const FeedListPage = () => {
    const [feeds, setFeeds] = useState([]);
    const navigate = useNavigate();
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);
    const [page, setPage] = useState(0); // 현재 페이지 번호
    const [hasMore, setHasMore] = useState(true); // 추가 데이터 존재 여부
    const [loading, setLoading] = useState(false); // 로딩 상태

    const observer = useRef();

    // 피드 제목 제한: 30글자 초과 시 "..." 처리
    const truncateTitle = (title) =>
        title.length > 30 ? title.substring(0, 30) + "..." : title;

    // 날짜 포맷 함수
    const formatDate = (date) => {
        const options = { year: "numeric", month: "long", day: "numeric" };
        return new Date(date).toLocaleDateString("ko-KR", options);
    };

    // 드롭다운 토글 함수
    const toggleDropdown = () => setIsDropdownOpen(!isDropdownOpen);

    // 오버레이 클릭 시 드롭다운 닫기
    const closeDropdown = () => setIsDropdownOpen(false);

    // 드롭다운 메뉴
    const dropdownMenu = isDropdownOpen && (
        <div className="w-48 bg-white border-2 border-[#9cb4cd] shadow-lg rounded-lg p-2 absolute bottom-20 right-6">
            <Link
                to="/feeds/create"
                className="w-auto flex items-center space-x-2 px-4 py-2 text-black hover:bg-[#9cb4cd] hover:text-white rounded"
            >
                <User className="w-6 h-6" />
                <span>글 쓰기</span>
            </Link>
            <hr className="my-2 border-1 border-[#9cb4cd]" />
            <Link
                to="/groupfeeds/create"
                className="w-auto flex items-center space-x-2 px-4 py-2 text-black hover:bg-[#9cb4cd] hover:text-white rounded"
            >
                <Users className="w-6 h-6" />
                <span>모임 글 쓰기</span>
            </Link>
        </div>
    );

    // API로부터 피드를 20개씩 불러오는 함수
    const fetchFeeds = async (pageNumber) => {
        setLoading(true);
        try {
            const response = await fetch(
                `http://localhost:8080/feeds?page=${pageNumber}&size=20`
            );
            if (response.ok) {
                const data = await response.json();
                let feedList = data.content || [];

                // createdAt 기준 최신순 정렬 (백엔드에서 정렬되어 있지 않은 경우)
                feedList.sort(
                    (a, b) => new Date(b.createdAt) - new Date(a.createdAt)
                );

                // 기존 피드에 추가
                setFeeds((prevFeeds) => [...prevFeeds, ...feedList]);

                // 만약 현재 페이지에서 불러온 피드 수가 요청한 페이지 사이즈보다 작다면 더 이상 불러올 데이터 없음
                if (feedList.length < 20) {
                    setHasMore(false);
                }
            } else {
                console.error("Failed to fetch feeds");
            }
        } catch (error) {
            console.error("Error fetching feeds:", error);
        }
        setLoading(false);
    };

    // 페이지 번호가 변경될 때마다 피드를 불러옴
    useEffect(() => {
        fetchFeeds(page);
    }, [page]);

    // 마지막 피드 엘리먼트를 관찰하여 다음 페이지를 로딩하는 IntersectionObserver
    const lastFeedRef = useCallback(
        (node) => {
            if (loading) return;
            if (observer.current) observer.current.disconnect();

            observer.current = new IntersectionObserver((entries) => {
                if (entries[0].isIntersecting && hasMore) {
                    setPage((prevPage) => prevPage + 1);
                }
            });
            if (node) observer.current.observe(node);
        },
        [loading, hasMore]
    );

    return (
        <div className="min-h-screen flex flex-col items-center w-full mt-16">
            {/* 드롭다운이 열려 있을 때 배경 오버레이 */}
            {isDropdownOpen && (
                <div
                    className="fixed inset-0 bg-black bg-opacity-50 z-40"
                    onClick={closeDropdown}
                ></div>
            )}
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-4 w-full max-w-3xl h-full flex-grow mb-10">
                {feeds.map((feed, index) => {
                    // 그룹 피드: feed에 chatRoomId 프로퍼티가 존재하면 그룹 피드, 그렇지 않으면 일반 피드
                    const isGroupFeed = Object.prototype.hasOwnProperty.call(feed, "chatRoomId");
                    // 기존 키 생성: 그룹 피드는 chatRoomId (UUID) 사용, 일반 피드는 feed.id 사용
                    const baseKey = isGroupFeed ? `groupfeed-${feed.chatRoomId}` : `feed-${feed.id}`;
                    // 수정: index를 포함하여 고유 키 생성 (임시 해결책)
                    const uniqueKey = `${baseKey}-${index}`;

                    if (index === feeds.length - 1) {
                        return (
                            <div
                                ref={lastFeedRef}
                                key={uniqueKey} // 수정된 부분: 고유키 사용
                                className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-400 shadow-2xl cursor-pointer transition relative mb-3"
                                onClick={() =>
                                    navigate(
                                        isGroupFeed ? `/groupfeeds/${feed.id}` : `/feeds/${feed.id}`
                                    )
                                }
                            >
                                <div className="flex flex-col items-start w-full">
                                    <div className="flex justify-between w-full items-center">
                                        <h2 className="text-2xl font-bold">
                                            {truncateTitle(feed.title)}
                                        </h2>
                                        {isGroupFeed && (
                                            <span className="px-3 py-1 text-sm text-white bg-[#9cb4cd] rounded-full -mr-2 -mt-1">
                                                # 모여요
                                            </span>
                                        )}
                                    </div>
                                    <p className="text-gray-600 text-sm mt-1">
                                        {formatDate(feed.createdAt)} ·{" "}
                                        {feed.authorNickname || "알 수 없음"}
                                    </p>
                                </div>
                                {/* 좋아요 및 댓글 수 표시 */}
                                <div className="absolute bottom-3 right-4 flex items-center space-x-3">
                                    <div className="flex items-center space-x-1">
                                        <Heart className="w-4 h-4 text-red-500" />
                                        <span className="text-gray-700">
                                            {isGroupFeed
                                                ? feed.likesCount !== undefined
                                                    ? feed.likesCount
                                                    : 0
                                                : feed.likesCount !== undefined
                                                    ? feed.likesCount
                                                    : 0}
                                        </span>
                                    </div>
                                    <div className="flex items-center space-x-1">
                                        <MessageCircle className="w-4 h-4 text-blue-500" />
                                        <span className="text-gray-700">
                                            {isGroupFeed
                                                ? feed.commentsCount !== undefined
                                                    ? feed.commentsCount
                                                    : 0
                                                : feed.commentsCount !== undefined
                                                    ? feed.commentsCount
                                                    : 0}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        );
                    } else {
                        return (
                            <div
                                key={uniqueKey} // 수정된 부분: 고유키 사용
                                className="bg-[#f5faff] py-5 px-7 rounded-xl shadow-blue-400 shadow-2xl cursor-pointer transition relative mb-3"
                                onClick={() =>
                                    navigate(
                                        isGroupFeed ? `/groupfeeds/${feed.id}` : `/feeds/${feed.id}`
                                    )
                                }
                            >
                                <div className="flex flex-col items-start w-full">
                                    <div className="flex justify-between w-full items-center">
                                        <h2 className="text-2xl font-bold">
                                            {truncateTitle(feed.title)}
                                        </h2>
                                        {isGroupFeed && (
                                            <span className="px-3 py-1 text-sm text-white bg-[#9cb4cd] rounded-full -mr-2 -mt-1">
                                                # 모여요
                                            </span>
                                        )}
                                    </div>
                                    <p className="text-gray-600 text-sm mt-1">
                                        {formatDate(feed.createdAt)} ·{" "}
                                        {feed.authorNickname || "알 수 없음"}
                                    </p>
                                </div>
                                {/* 좋아요 및 댓글 수 표시 */}
                                <div className="absolute bottom-3 right-4 flex items-center space-x-3">
                                    <div className="flex items-center space-x-1">
                                        <Heart className="w-4 h-4 text-red-500" />
                                        <span className="text-gray-700">
                                            {isGroupFeed
                                                ? feed.likesCount !== undefined
                                                    ? feed.likesCount
                                                    : 0
                                                : feed.likesCount !== undefined
                                                    ? feed.likesCount
                                                    : 0}
                                        </span>
                                    </div>
                                    <div className="flex items-center space-x-1">
                                        <MessageCircle className="w-4 h-4 text-blue-500" />
                                        <span className="text-gray-700">
                                            {isGroupFeed
                                                ? feed.commentsCount !== undefined
                                                    ? feed.commentsCount
                                                    : 0
                                                : feed.commentsCount !== undefined
                                                    ? feed.commentsCount
                                                    : 0}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        );
                    }
                })}
                {loading && (
                    <p className="text-center text-gray-500 mt-5">로딩 중...</p>
                )}
                {!hasMore && (
                    <p className="text-center text-gray-500 mb-7">
                        더 이상 불러올 피드가 없습니다.
                    </p>
                )}
            </div>

            {/* 플로팅 버튼 및 드롭다운 메뉴 */}
            <div className="fixed bottom-20 right-3 flex flex-col items-end z-50">
                {dropdownMenu}
                <button
                    onClick={toggleDropdown}
                    className="border-4 border-[#9cb4cd] bg-white text-[#9cb4cd] w-16 h-16 rounded-full flex items-center justify-center shadow-xl hover:bg-[#9cb4cd] hover:text-white focus:outline-none focus:ring-2 focus:ring-[#9cb4cd]"
                >
                    {isDropdownOpen ? <X className="w-10 h-10" /> : <Plus className="w-10 h-10" />}
                </button>
            </div>
        </div>
    );
};

export default FeedListPage;