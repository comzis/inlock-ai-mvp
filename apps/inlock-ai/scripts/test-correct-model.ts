import { GoogleGenerativeAI } from '@google/generative-ai';

async function testCorrectModel() {
    const apiKey = process.env.GOOGLE_AI_API_KEY || 'AIzaSyA3bV2yhqgWxFNgB-oENkYZnyMYR8sI--g';

    console.log('Testing with correct model name (models/gemini-2.0-flash)...\n');

    const genAI = new GoogleGenerativeAI(apiKey);

    try {
        const model = genAI.getGenerativeModel({ model: 'models/gemini-2.0-flash' });
        const result = await model.generateContent('Say hello in one sentence');
        const response = await result.response;
        console.log('✅ Success! Response:', response.text());
    } catch (error: any) {
        console.log('❌ Error:', error.message);
    }
}

testCorrectModel();
