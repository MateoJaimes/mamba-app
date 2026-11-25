import { Controller, ForbiddenException, Get, Headers, Param, Post, Res } from '@nestjs/common';
import type { Response } from 'express';
import { join } from 'node:path';
import { SupabaseService } from './supabase.service';
import { MailService } from './mail.service';

@Controller()
export class AppController {
  constructor(private readonly supabase:SupabaseService,private readonly mail:MailService){}
  @Get('api/health')health(){return {service:'MAPO',framework:'NestJS',status:'ok',version:'1.0.0'};}
  @Get()home(@Res()res:Response){return res.sendFile(join(process.cwd(),'public/index.html'));}
  @Get('branding/:file')brand(@Param('file')file:string,@Res()res:Response){
    if(!['mapo-logo.png','mapo-symbol.png','mapo-icon.png'].includes(file))return res.status(404).end();
    res.setHeader('Cache-Control','public, max-age=86400');
    return res.sendFile(join(process.cwd(),'public/branding',file));
  }
  @Get('auth/callback')callback(@Res()res:Response){res.setHeader('Cache-Control','no-store');res.setHeader('Referrer-Policy','no-referrer');return res.sendFile(join(process.cwd(),'public/auth/callback.html'));}
  @Get('api/feed')async feed(@Res()res:Response){const r=await this.supabase.request('/rest/v1/experience_feed?select=*&order=published_at.desc&limit=20','GET');return res.status(r.status).json(await r.json());}
  @Post('api/mail/test')async testMail(@Headers('authorization')token?:string){
    const user=await this.supabase.user(token);
    const r=await this.supabase.request('/rest/v1/user_roles?select=role&role=eq.admin','GET',token);
    const roles=await r.json();if(!r.ok||!Array.isArray(roles)||!roles.length)throw new ForbiddenException('Solo administración');
    return this.mail.testToOwner(user.email??'');
  }
}
