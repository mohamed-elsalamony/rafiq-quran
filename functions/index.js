import { onRequest } from "firebase-functions/v2/https";
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { GoogleGenerativeAI } from '@google/generative-ai';

// تحميل متغيرات البيئة محلياً (لو كان هناك ملف .env)
dotenv.config();

const app = express();

// تفعيل CORS
app.use(cors({ origin: true }));
app.use(express.json());

const SYSTEM_INSTRUCTION = `
أنت مساعد ذكاء اصطناعي إسلامي وعام ذكي وموثوق لـ "رفيق القرآن".
مهمتك هي الإجابة عن كافة أسئلة واستفسارات المستخدمين بطلاقة ودقة مع الالتزام الصارم بالضوابط التالية:
1. الحذر الشديد والأمانة العلمية: لا تقم باخترع أو اختلاق آيات قرآنية أو أحاديث نبوية مطلقاً.
2. التوثيق الدقيق: عند ذكر أي آية قرآنية، يجب عليك تحديد اسم السورة ورقم الآية بدقة (مثال: سورة البقرة، الآية 255).
3. الأمانة عند عدم المعرفة: إذا لم تكن متأكداً من معلومة أو إجابة، صرّح بذلك بأدب (مثال: "الله أعلم، لا تتوفر لدي معلومات موثقة حول هذا الموضوع").
4. عدم الفتوى الفردية: لا تقدم فتاوى شرعية مستقلة أو أحكاماً فقهية جازمة من تلقاء نفسك، بل اعرض الآراء الفقهية للمذاهب الأربعة المعتمدة عند الحاجة، ووجّه السائل دائماً لاستشارة العلماء والجهات الفقهية المختصة.
5. الأسلوب والوقار: تحدث بلغة عربية فصحى مبسطة، بأسلوب مهذب، واضح، ومحترم يليق بمساعد إسلامي.
`;

// 1. منفذ فحص الحالة (Health Check)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'خادم رفيق المساعد الذكي يعمل بنجاح على Firebase Cloud Functions.',
    timestamp: new Date().toISOString()
  });
});

// 2. منفذ المحادثة الرئيسي (POST /api/chat)
app.post('/api/chat', async (req, res) => {
  const { message, history } = req.body;

  if (!message || message.trim() === '') {
    return res.status(400).json({
      success: false,
      error: 'حقل الرسالة (message) مطلوب ولا يمكن أن يكون فارغاً.'
    });
  }

  // في Firebase Cloud Functions، يتم قراءة مفتاح الـ API من متغيرات البيئة
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey.trim() === '') {
    return res.status(500).json({
      success: false,
      error: 'مفتاح Gemini API غير مهيأ في إعدادات البيئة لـ Cloud Functions. يرجى تهيئته.'
    });
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const modelName = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
    
    const model = genAI.getGenerativeModel({
      model: modelName,
      systemInstruction: SYSTEM_INSTRUCTION,
    });

    const formattedHistory = (history || []).map(item => {
      if (item.parts && Array.isArray(item.parts)) {
        return {
          role: item.role === 'model' ? 'model' : 'user',
          parts: item.parts.map(p => ({ text: p.text || '' }))
        };
      }
      return {
        role: item.role === 'model' ? 'model' : 'user',
        parts: [{ text: item.content || item.text || '' }]
      };
    });

    const chat = model.startChat({
      history: formattedHistory,
      generationConfig: {
        maxOutputTokens: 2048,
        temperature: 0.7,
      }
    });

    const result = await chat.sendMessage(message);
    const response = await result.response;
    const replyText = response.text();

    res.status(200).json({
      success: true,
      reply: replyText,
      model: modelName
    });
  } catch (error) {
    console.error('Gemini API Error:', error);
    res.status(500).json({
      success: false,
      error: `فشل الاتصال بنموذج الذكاء الاصطناعي: ${error.message || error}`
    });
  }
});

// تشغيل السيرفر بشكل مستقل عند استضافته على منصات مثل Render
const PORT = process.env.PORT || 3000;
if (!process.env.FUNCTIONS_EMULATOR && !process.env.FIREBASE_CONFIG) {
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

// تصدير تطبيق Express كـ Firebase Cloud Function باسم 'api'
export const api = onRequest({ cors: true, timeoutSeconds: 60, memory: "256MiB" }, app);
