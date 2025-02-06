import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import axios from "axios";
import { Heart } from "lucide-react";

function FeedDetailPage() {
    const { id } = useParams();
    const [feed, setFeed] = useState(null);
    const [comments, setComments] = useState([]);
    const [newComment, setNewComment] = useState("");
    const [currentUser, setCurrentUser] = useState(null);
    const [isLiked, setIsLiked] = useState(false);
    const [likeCount, setLikeCount] = useState(0);

    // ✅ 현재 로그인된 사용자 가져오기
    const checkUser = () => {
        const token = localStorage.getItem("token");
        if (token) {
            try {
                const payload = JSON.parse(atob(token.split(".")[1])); // JWT 디코딩
                setCurrentUser(payload.sub);
            } catch (error) {
                console.error("토큰 디코딩 오류:", error);
            }
        }
    };

    // ✅ 현재 사용자가 해당 피드에 좋아요를 눌렀는지 확인
    const fetchLikeStatus = async () => {
        if (!currentUser) return; // 로그인하지 않은 사용자는 좋아요 안 누른 상태 유지

        try {
            const response = await axios.get(`http://localhost:8080/feeds/${id}/like/status`, {
                headers: { Authorization: `Bearer ${localStorage.getItem("token")}` },
            });

            setIsLiked(response.data.liked); // ✅ 사용자가 해당 피드에 좋아요를 눌렀는지 여부
        } catch (error) {
            console.error("좋아요 상태 불러오기 실패:", error);
        }
    };

    // ✅ 게시글 상세 정보 및 댓글 가져오기
    useEffect(() => {
        const fetchFeedDetails = async () => {
            try {
                const response = await axios.get(`http://localhost:8080/feeds/${id}`);
                setFeed(response.data);
                setLikeCount(response.data.likeCount || 0); // ✅ 좋아요 개수 저장만 해놓음
            } catch (error) {
                console.error("게시글 불러오기 실패:", error);
            }
        };

        const fetchComments = async () => {
            try {
                const response = await axios.get(`http://localhost:8080/feeds/${id}/comments`);
                setComments(response.data.reverse());
            } catch (error) {
                console.error("댓글 불러오기 실패:", error);
            }
        };

        fetchFeedDetails();
        fetchComments();
        checkUser();
    }, [id]);

    // ✅ 로그인된 사용자가 있을 때 좋아요 상태 확인
    useEffect(() => {
        if (currentUser) {
            fetchLikeStatus();
        }
    }, [currentUser]);

    // ✅ 좋아요 토글 함수
    const toggleLike = async () => {
        if (!currentUser) {
            alert("로그인이 필요합니다.");
            return;
        }

        try {
            await axios.post(
                `http://localhost:8080/feeds/${id}/like`,
                {},
                { headers: { Authorization: `Bearer ${localStorage.getItem("token")}` } }
            );

            setIsLiked((prev) => !prev);
            setLikeCount((prev) => (isLiked ? prev - 1 : prev + 1));

            // ✅ 좋아요 상태 최신화
            fetchLikeStatus();
        } catch (error) {
            console.error("좋아요 실패:", error);
        }
    };

    // ✅ 날짜 포맷 함수
    const formatDate = (dateString) => {
        const date = new Date(dateString);
        return isNaN(date.getTime()) ? "날짜 오류" : date.toLocaleString("ko-KR");
    };

    // ✅ 댓글 작성 함수
    const handleCommentSubmit = async () => {
        if (!newComment.trim()) {
            alert("댓글을 입력하세요.");
            return;
        }

        if (!currentUser) {
            alert("로그인이 필요합니다.");
            return;
        }

        try {
            const response = await axios.post(
                `http://localhost:8080/feeds/${id}/comments`,
                { content: newComment },
                {
                    headers: {
                        Authorization: `Bearer ${localStorage.getItem("token")}`,
                        "Content-Type": "application/json"
                    },
                    withCredentials: true
                }
            );

            if (response.status === 200) {
                setComments((prevComments) => [response.data, ...prevComments]);
                setNewComment("");
            }
        } catch (error) {
            console.error("댓글 작성 실패:", error);
            alert("댓글 작성에 실패했습니다.");
        }
    };

    if (!feed) return <p>로딩 중...</p>;

    return (
        <div className="min-h-screen flex flex-col items-center w-full">
            <div className="bg-white shadow-lg shadow-blue-200 rounded-lg p-6 w-full max-w-3xl">
                {/* 제목 및 작성자 정보 */}
                <div className="text-left">
                    <h1 className="text-3xl font-bold">{feed.title}</h1>
                    <p className="text-sm text-gray-500 mt-2">
                        작성자: {feed.author?.nickname || "알 수 없음"} <br />
                        {formatDate(feed.createdAt)}
                    </p>
                </div>
                <hr className="border-t-[1px] border-[#9cb4cd] my-4" />

                {/* 본문 */}
                <p className="text-gray-700">{feed.content}</p>
                <hr className="border-t-[1px] border-[#9cb4cd] my-4" />

                {/* ✅ 좋아요 버튼 */}
                <div className="mt-3 flex justify-end">
                    <button
                        onClick={toggleLike}
                        className={`flex items-center space-x-2 px-2 py-2 rounded-lg border transition 
                        ${isLiked ? "bg-[#9cb4cd] text-white" : "bg-white text-[#9cb4cd] border-[#9cb4cd]"}`}
                    >
                        <Heart
                            className={`w-6 h-6 transition ${isLiked ? "fill-white stroke-white" : "stroke-[#9cb4cd]"}`}
                        />
                    </button>
                </div>

                {/* ✅ 댓글 입력창 */}
                <div className="my-4 w-full">
                    <h2 className="text-xl font-bold">댓글 {comments.length}</h2>

                    {/* 댓글 입력창 */}
                    <textarea
                        value={newComment}
                        onChange={(e) => setNewComment(e.target.value)}
                        className="border w-full p-3 rounded mt-2"
                        rows="3"
                        placeholder="댓글을 입력하세요"
                    ></textarea>

                    {/* 댓글 추가 버튼 */}
                    <button
                        onClick={handleCommentSubmit}
                        className="bg-[#9cb4cd] text-white px-4 py-2 rounded mt-2 hover:bg-[#b3c7de] transition w-full"
                    >
                        댓글 추가
                    </button>

                    {/* 댓글 리스트 */}
                    <ul className="mt-4 w-full">
                        {comments.map((comment) => (
                            <li key={comment.id} className="border-b py-2">
                                <p>{comment.content}</p>
                                <p className="text-sm text-gray-400">
                                    {comment.author?.nickname || "익명"} | {formatDate(comment.createdAt)}
                                </p>
                            </li>
                        ))}
                    </ul>
                </div>
            </div>
        </div>
    );
}

export default FeedDetailPage;