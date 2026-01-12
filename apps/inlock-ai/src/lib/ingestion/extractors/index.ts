export async function extractText(buffer: Buffer, mimeType: string): Promise<string> {
    if (mimeType.startsWith("text/") || mimeType === "application/json") {
        return buffer.toString("utf-8");
    }
    // TODO: Add PDF (pdf-parse) and DOCX (mammoth) support
    if (mimeType === "application/pdf") {
        return "[PDF content extraction not implemented in v0.1 pilot - install pdf-parse]";
    }
    if (mimeType === "application/vnd.openxmlformats-officedocument.wordprocessingml.document") {
        return "[DOCX content extraction not implemented in v0.1 pilot - install mammoth]";
    }
    return "";
}
