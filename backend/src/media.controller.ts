import { BadRequestException, Controller, Get, Headers, Param, ParseUUIDPipe, Post, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { randomUUID } from 'node:crypto';
import sharp from 'sharp';
import type { Response } from 'express';
import { SupabaseService } from './supabase.service';

@Controller('api/media')
export class MediaController {
  constructor(private readonly supabase:SupabaseService){}

  @Get(':owner/:file')
  async download(
    @Param('owner', new ParseUUIDPipe()) owner: string,
    @Param('file') file: string,
    @Headers('authorization') token: string | undefined,
    @Res() response: Response,
  ) {
    response.setHeader('Cache-Control', 'private, no-store');
    response.setHeader('X-Content-Type-Options', 'nosniff');
    if (!/^[a-f0-9-]{36}\.webp$/i.test(file)) return response.status(404).end();
    const upstream = await this.supabase.downloadPhoto(owner, file, token);
    if (!upstream.ok) return response.status(upstream.status >= 500 ? 502 : 404).end();
    return response.type('image/webp').send(Buffer.from(await upstream.arrayBuffer()));
  }
  @Post()
  @UseInterceptors(FileInterceptor('photo',{limits:{fileSize:3*1024*1024,files:1}}))
  async upload(@Headers('authorization')token:string,@UploadedFile()file?:Express.Multer.File){
    const user=await this.supabase.user(token);
    if(!file)throw new BadRequestException('Selecciona una foto');
    let optimized:Buffer;
    try {
      const image=sharp(file.buffer,{limitInputPixels:24000000});
      const metadata=await image.metadata();
      if(!['jpeg','png','webp','heif'].includes(metadata.format??''))throw new Error('format');
      optimized=await image.rotate().resize(1600,1600,{fit:'inside',withoutEnlargement:true}).webp({quality:82}).toBuffer();
    }catch{throw new BadRequestException('Usa una foto JPG, PNG o WebP válida');}
    const url=await this.supabase.uploadPhoto(user.id,token,optimized,randomUUID()+'.webp');
    return {url};
  }
}
