var zlib = context.global.get('zlib');
msg.payload = 
    zlib.gzipSync(JSON.stringify(msg.payload)).
            toString('base64');

return msg;

