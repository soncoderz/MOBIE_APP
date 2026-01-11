const { GoogleGenerativeAI } = require('@google/generative-ai');
const Doctor = require('../models/Doctor');
const Hospital = require('../models/Hospital');
const Specialty = require('../models/Specialty');
const Service = require('../models/Service');
const Appointment = require('../models/Appointment');
const Review = require('../models/Review');
const ChatHistory = require('../models/ChatHistory');

// Initialize Gemini AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Helper function to get doctors list with ratings
const getDoctorsList = async (filters = {}) => {
    try {
        let query = Doctor.find()
            .populate('user', 'fullName email phoneNumber avatar')
            .populate('specialtyId', 'name')
            .populate('hospitalId', 'name address')
            .sort({ 'ratings.average': -1 });

        if (filters.specialtyId) {
            query = query.where('specialtyId').equals(filters.specialtyId);
        }
        if (filters.hospitalId) {
            query = query.where('hospitalId').equals(filters.hospitalId);
        }

        const doctors = await query.limit(10).lean();

        return doctors.map(doc => ({
            id: doc._id,
            name: doc.user?.fullName || 'Không xác định',
            avatar: doc.user?.avatar || null,
            title: doc.title,
            specialty: doc.specialtyId?.name || 'Chưa xác định',
            hospital: doc.hospitalId?.name || 'Chưa xác định',
            experience: doc.experience,
            rating: doc.ratings?.average || doc.averageRating || 0,
            ratingCount: doc.ratings?.count || 0,
            consultationFee: doc.consultationFee,
            isAvailable: doc.isAvailable
        }));
    } catch (error) {
        console.error('Error fetching doctors:', error);
        return [];
    }
};

// Get hospitals/branches list
const getHospitalsList = async () => {
    try {
        const hospitals = await Hospital.find({ isActive: true })
            .populate('specialties', 'name')
            .sort({ 'ratings.average': -1 })
            .limit(10)
            .lean();

        return hospitals.map(h => ({
            id: h._id,
            name: h.name,
            address: h.address,
            phone: h.contactInfo?.phone,
            imageUrl: h.imageUrl || h.image?.url || h.image?.secureUrl || null,
            rating: h.ratings?.average || 0,
            isMainHospital: h.isMainHospital,
            specialties: h.specialties?.map(s => s.name) || []
        }));
    } catch (error) {
        console.error('Error fetching hospitals:', error);
        return [];
    }
};

// Get specialties list
const getSpecialtiesList = async () => {
    try {
        const specialties = await Specialty.find({ isActive: true })
            .sort({ name: 1 })
            .lean();

        return specialties.map(s => ({
            id: s._id,
            name: s.name,
            description: s.description,
            icon: s.icon,
            imageUrl: s.imageUrl || s.image?.url || s.image?.secureUrl || null
        }));
    } catch (error) {
        console.error('Error fetching specialties:', error);
        return [];
    }
};

// Get services list
const getServicesList = async (filters = {}) => {
    try {
        let query = Service.find({ isActive: true })
            .populate('specialtyId', 'name')
            .sort({ name: 1 });

        if (filters.specialtyId) {
            query = query.where('specialtyId').equals(filters.specialtyId);
        }

        const services = await query.limit(20).lean();

        return services.map(s => ({
            id: s._id,
            name: s.name,
            description: s.shortDescription || s.description,
            price: s.price,
            duration: s.duration,
            specialty: s.specialtyId?.name || 'Chưa xác định',
            type: s.type,
            imageUrl: s.imageUrl || s.image?.url || s.image?.secureUrl || null
        }));
    } catch (error) {
        console.error('Error fetching services:', error);
        return [];
    }
};

// Get user's appointments
const getUserAppointments = async (userId, type = 'all') => {
    try {
        const now = new Date();
        let query = Appointment.find({ patientId: userId })
            .populate({
                path: 'doctorId',
                populate: { path: 'user', select: 'fullName' }
            })
            .populate('hospitalId', 'name address')
            .populate('specialtyId', 'name')
            .populate('serviceId', 'name price')
            .sort({ appointmentDate: -1 });

        if (type === 'upcoming') {
            query = query.where('appointmentDate').gte(now)
                .where('status').in(['pending', 'confirmed', 'pending_payment']);
        } else if (type === 'current') {
            const startOfDay = new Date(now.setHours(0, 0, 0, 0));
            const endOfDay = new Date(now.setHours(23, 59, 59, 999));
            query = query.where('appointmentDate').gte(startOfDay).lte(endOfDay);
        }

        const appointments = await query.limit(10).lean();

        return appointments.map(a => ({
            id: a._id,
            bookingCode: a.bookingCode,
            date: a.appointmentDate,
            timeSlot: a.timeSlot,
            status: a.status,
            doctor: a.doctorId?.user?.fullName || 'Không xác định',
            hospital: a.hospitalId?.name || 'Không xác định',
            specialty: a.specialtyId?.name || 'Không xác định',
            service: a.serviceId?.name,
            totalAmount: a.fee?.totalAmount || 0
        }));
    } catch (error) {
        console.error('Error fetching appointments:', error);
        return [];
    }
};

// Get top rated doctors
const getTopRatedDoctors = async (limit = 5) => {
    try {
        const doctors = await Doctor.find({ isAvailable: true })
            .populate('user', 'fullName avatar')
            .populate('specialtyId', 'name')
            .populate('hospitalId', 'name')
            .sort({ 'ratings.average': -1, 'ratings.count': -1 })
            .limit(limit)
            .lean();

        return doctors.map(doc => ({
            id: doc._id,
            name: doc.user?.fullName || 'Không xác định',
            avatar: doc.user?.avatar || null,
            title: doc.title,
            specialty: doc.specialtyId?.name || 'Chưa xác định',
            hospital: doc.hospitalId?.name || 'Chưa xác định',
            rating: doc.ratings?.average || doc.averageRating || 0,
            ratingCount: doc.ratings?.count || 0,
            experience: doc.experience
        }));
    } catch (error) {
        console.error('Error fetching top rated doctors:', error);
        return [];
    }
};

// Detect user intent from message
const detectIntent = (message) => {
    const lowerMessage = message.toLowerCase();

    // Doctor related
    if (lowerMessage.includes('bác sĩ') || lowerMessage.includes('bac si') || lowerMessage.includes('doctor')) {
        if (lowerMessage.includes('đánh giá cao') || lowerMessage.includes('tốt nhất') || lowerMessage.includes('top') || lowerMessage.includes('rating')) {
            return 'top_rated_doctors';
        }
        return 'list_doctors';
    }

    // Hospital/branch related
    if (lowerMessage.includes('chi nhánh') || lowerMessage.includes('bệnh viện') || lowerMessage.includes('phòng khám') ||
        lowerMessage.includes('benh vien') || lowerMessage.includes('hospital') || lowerMessage.includes('clinic')) {
        return 'list_hospitals';
    }

    // Specialty related
    if (lowerMessage.includes('chuyên khoa') || lowerMessage.includes('chuyen khoa') || lowerMessage.includes('specialty')) {
        return 'list_specialties';
    }

    // Service related
    if (lowerMessage.includes('dịch vụ') || lowerMessage.includes('dich vu') || lowerMessage.includes('service') ||
        lowerMessage.includes('giá') || lowerMessage.includes('gia') || lowerMessage.includes('price')) {
        return 'list_services';
    }

    // Appointment related
    if (lowerMessage.includes('lịch hẹn') || lowerMessage.includes('lich hen') || lowerMessage.includes('appointment') ||
        lowerMessage.includes('cuộc hẹn') || lowerMessage.includes('đặt khám')) {
        if (lowerMessage.includes('sắp tới') || lowerMessage.includes('sap toi') || lowerMessage.includes('upcoming')) {
            return 'upcoming_appointments';
        }
        if (lowerMessage.includes('hôm nay') || lowerMessage.includes('hom nay') || lowerMessage.includes('today') || lowerMessage.includes('hiện tại')) {
            return 'current_appointments';
        }
        return 'all_appointments';
    }

    return 'general';
};

// Format data for AI response
const formatDataForAI = (data, dataType) => {
    if (!data || data.length === 0) {
        return 'Không tìm thấy dữ liệu.';
    }

    let formatted = '';

    switch (dataType) {
        case 'doctors':
            formatted = data.map((d, i) =>
                `${i + 1}. ${d.title} ${d.name} - ${d.specialty} tại ${d.hospital} (${d.experience} năm kinh nghiệm, đánh giá: ${d.rating.toFixed(1)}/5)`
            ).join('\n');
            break;

        case 'hospitals':
            formatted = data.map((h, i) =>
                `${i + 1}. ${h.name}${h.isMainHospital ? ' (Trụ sở chính)' : ''}\n   Địa chỉ: ${h.address}\n   Điện thoại: ${h.phone || 'N/A'}\n   Đánh giá: ${h.rating.toFixed(1)}/5`
            ).join('\n\n');
            break;

        case 'specialties':
            formatted = data.map((s, i) =>
                `${i + 1}. ${s.name}${s.description ? ` - ${s.description}` : ''}`
            ).join('\n');
            break;

        case 'services':
            formatted = data.map((s, i) =>
                `${i + 1}. ${s.name} (${s.specialty})\n   Giá: ${s.price?.toLocaleString('vi-VN')} VNĐ\n   Thời gian: ${s.duration} phút`
            ).join('\n\n');
            break;

        case 'appointments':
            formatted = data.map((a, i) => {
                const date = new Date(a.date).toLocaleDateString('vi-VN');
                const statusMap = {
                    'pending': 'Chờ xác nhận',
                    'confirmed': 'Đã xác nhận',
                    'completed': 'Hoàn thành',
                    'cancelled': 'Đã hủy',
                    'pending_payment': 'Chờ thanh toán',
                    'rescheduled': 'Đã đổi lịch'
                };
                return `${i + 1}. Mã: ${a.bookingCode}\n   Ngày: ${date} - ${a.timeSlot?.startTime || 'N/A'}\n   Bác sĩ: ${a.doctor}\n   Bệnh viện: ${a.hospital}\n   Trạng thái: ${statusMap[a.status] || a.status}`;
            }).join('\n\n');
            break;

        default:
            formatted = JSON.stringify(data, null, 2);
    }

    return formatted;
};

// @desc    Send message to AI chatbot and get response
// @route   POST /api/chatbot/message
// @access  Private
const sendMessage = async (req, res) => {
    try {
        const { message } = req.body;
        const userId = req.user._id;

        if (!message || message.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng nhập tin nhắn'
            });
        }

        // Detect intent
        const intent = detectIntent(message);
        let contextData = null;
        let dataType = '';
        let structuredData = null;

        // Fetch relevant data based on intent
        switch (intent) {
            case 'list_doctors':
                contextData = await getDoctorsList();
                dataType = 'doctors';
                structuredData = { type: 'doctors', items: contextData };
                break;

            case 'top_rated_doctors':
                contextData = await getTopRatedDoctors(5);
                dataType = 'doctors';
                structuredData = { type: 'doctors', items: contextData };
                break;

            case 'list_hospitals':
                contextData = await getHospitalsList();
                dataType = 'hospitals';
                structuredData = { type: 'hospitals', items: contextData };
                break;

            case 'list_specialties':
                contextData = await getSpecialtiesList();
                dataType = 'specialties';
                structuredData = { type: 'specialties', items: contextData };
                break;

            case 'list_services':
                contextData = await getServicesList();
                dataType = 'services';
                structuredData = { type: 'services', items: contextData };
                break;

            case 'upcoming_appointments':
                contextData = await getUserAppointments(userId, 'upcoming');
                dataType = 'appointments';
                structuredData = { type: 'appointments', items: contextData };
                break;

            case 'current_appointments':
                contextData = await getUserAppointments(userId, 'current');
                dataType = 'appointments';
                structuredData = { type: 'appointments', items: contextData };
                break;

            case 'all_appointments':
                contextData = await getUserAppointments(userId, 'all');
                dataType = 'appointments';
                structuredData = { type: 'appointments', items: contextData };
                break;
        }

        // Build context for AI
        let systemContext = `Bạn là trợ lý AI của hệ thống đặt lịch khám bệnh online. 
Bạn giúp người dùng tìm kiếm thông tin về bác sĩ, bệnh viện, chuyên khoa, dịch vụ y tế và quản lý lịch hẹn.
Hãy trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp.
Nếu có dữ liệu được cung cấp, hãy tóm tắt và trình bày dễ hiểu cho người dùng.`;

        if (contextData && contextData.length > 0) {
            const formattedData = formatDataForAI(contextData, dataType);
            systemContext += `\n\nDữ liệu từ hệ thống:\n${formattedData}`;
        } else if (intent !== 'general') {
            systemContext += '\n\nHiện tại không có dữ liệu phù hợp với yêu cầu của người dùng.';
        }

        // Generate AI response
        const model = genAI.getGenerativeModel({ model: 'gemini-3-flash-preview' });

        const prompt = `${systemContext}\n\nCâu hỏi của người dùng: ${message}`;

        const result = await model.generateContent(prompt);
        const aiResponse = result.response.text();

        // Save to chat history
        try {
            await ChatHistory.findOneAndUpdate(
                { userId },
                {
                    $push: {
                        messages: [
                            { role: 'user', content: message, timestamp: new Date() },
                            { role: 'assistant', content: aiResponse, timestamp: new Date() }
                        ]
                    }
                },
                { upsert: true, new: true }
            );
        } catch (historyError) {
            console.error('Error saving chat history:', historyError);
        }

        res.json({
            success: true,
            data: {
                message: aiResponse,
                intent,
                structuredData,
                timestamp: new Date()
            }
        });

    } catch (error) {
        console.error('Chatbot error:', error);
        res.status(500).json({
            success: false,
            message: 'Có lỗi xảy ra khi xử lý tin nhắn',
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
};

// @desc    Get chat history
// @route   GET /api/chatbot/history
// @access  Private
const getChatHistory = async (req, res) => {
    try {
        const userId = req.user._id;

        const history = await ChatHistory.findOne({ userId })
            .select('messages')
            .lean();

        res.json({
            success: true,
            data: {
                messages: history?.messages || []
            }
        });

    } catch (error) {
        console.error('Error fetching chat history:', error);
        res.status(500).json({
            success: false,
            message: 'Có lỗi xảy ra khi lấy lịch sử chat'
        });
    }
};

// @desc    Clear chat history
// @route   DELETE /api/chatbot/history
// @access  Private
const clearChatHistory = async (req, res) => {
    try {
        const userId = req.user._id;

        await ChatHistory.findOneAndUpdate(
            { userId },
            { $set: { messages: [] } }
        );

        res.json({
            success: true,
            message: 'Đã xóa lịch sử chat'
        });

    } catch (error) {
        console.error('Error clearing chat history:', error);
        res.status(500).json({
            success: false,
            message: 'Có lỗi xảy ra khi xóa lịch sử chat'
        });
    }
};

module.exports = {
    sendMessage,
    getChatHistory,
    clearChatHistory
};
