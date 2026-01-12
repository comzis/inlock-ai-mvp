import { GoogleGenerativeAI } from '@google/generative-ai';

async function testGemini() {
    const apiKey = process.env.GOOGLE_AI_API_KEY || '';
    if (!apiKey) {
        console.log('❌ No API key found in GOOGLE_AI_API_KEY');
        process.exit(1);
    }

    console.log('Testing Gemini SDK...\n');

    const genAI = new GoogleGenerativeAI(apiKey);

    // Test 1: Try gemini-1.5-flash
    console.log('1. Testing gemini-1.5-flash:');
    try {
        const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
        const result = await model.generateContent('Say hello');
        const response = await result.response;
        console.log('   ✅ Works! Response:', response.text().substring(0, 50) + '...');
    } catch (error: any) {
        console.log('   ❌ Error:', error.message.substring(0, 100));
    }

    // Test 2: Try gemini-pro
    console.log('\n2. Testing gemini-pro:');
    try {
        const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
        const result = await model.generateContent('Say hello');
        const response = await result.response;
        console.log('   ✅ Works! Response:', response.text().substring(0, 50) + '...');
    } catch (error: any) {
        console.log('   ❌ Error:', error.message.substring(0, 100));
    }

    // Test 3: Try streaming
    console.log('\n3. Testing streaming:');
    try {
        const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
        const result = await model.generateContentStream('Count to 5');

        console.log('   Stream chunks: ');
        for await (const chunk of result.stream) {
            const text = chunk.text();
            if (text) process.stdout.write(text);
        }
        console.log('\n   ✅ Streaming works!');
    } catch (error: any) {
        console.log('   ❌ Error:', error.message.substring(0, 100));
    }
}

testGemini();
