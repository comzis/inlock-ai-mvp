const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '../../../');
const CONTENT_DIR = path.join(PROJECT_ROOT, 'apps/inlock-ai/content');
const BLOG_METADATA_FILE = path.join(PROJECT_ROOT, 'apps/inlock-ai/src/lib/blog.ts');

// Ensure arguments are provided
if (process.argv.length < 3) {
    console.error('Usage: node add-blog-post.js <json_data_or_file_path>');
    process.exit(1);
}

let inputData;
try {
    const inputArg = process.argv[2];
    // Try parsing as JSON first, otherwise treat as file path
    if (inputArg.trim().startsWith('{')) {
        inputData = JSON.parse(inputArg);
    } else {
        inputData = JSON.parse(fs.readFileSync(inputArg, 'utf8'));
    }
} catch (error) {
    console.error('Error parsing input JSON:', error.message);
    process.exit(1);
}

// Validate input
const requiredFields = ['slug', 'title', 'date', 'readTime', 'excerpt', 'content', 'pillars', 'productAngle'];
for (const field of requiredFields) {
    if (!inputData[field]) {
        console.error(`Missing required field: ${field}`);
        process.exit(1);
    }
}

// 1. Write Content File
const fileName = `${inputData.slug}.md`;
const filePath = path.join(CONTENT_DIR, fileName);
const fileContent = inputData.content;

try {
    fs.writeFileSync(filePath, fileContent);
    console.log(`✅ Created blog post file: ${filePath}`);
} catch (error) {
    console.error('Error writing content file:', error.message);
    process.exit(1);
}

// 2. Update Metadata
try {
    let blogTsContent = fs.readFileSync(BLOG_METADATA_FILE, 'utf8');
    
    const newEntry = {
        slug: inputData.slug,
        title: inputData.title,
        date: inputData.date,
        readTime: inputData.readTime,
        excerpt: inputData.excerpt,
        file: fileName,
        pillars: inputData.pillars,
        productAngle: inputData.productAngle,
    };
    
    if (inputData.locales) {
        newEntry.locales = inputData.locales;
    }

    // specific formatting to match existing TS file (somewhat)
    const newEntryString = `  ${JSON.stringify(newEntry, null, 4)},\n`;
    
    // Find the array start
    const arrayStartMarker = 'export const blogPosts: BlogMeta[] = [';
    const insertPosition = blogTsContent.indexOf(arrayStartMarker);
    
    if (insertPosition === -1) {
        throw new Error('Could not find blogPosts array in blog.ts');
    }
    
    const insertionPoint = insertPosition + arrayStartMarker.length;
    const newContent = blogTsContent.slice(0, insertionPoint) + '\n' + newEntryString + blogTsContent.slice(insertionPoint);
    
    fs.writeFileSync(BLOG_METADATA_FILE, newContent);
    console.log(`✅ Updated metadata file: ${BLOG_METADATA_FILE}`);

} catch (error) {
    console.error('Error updating metadata:', error.message);
    process.exit(1);
}

console.log('🎉 Blog post added successfully!');
