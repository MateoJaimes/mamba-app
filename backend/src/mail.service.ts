import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class MailService {
  constructor(private readonly config:ConfigService){}
  get ready(){return Boolean(this.config.get<string>('SMTP_PASSWORD'));}
  async testToOwner(email:string){
    if(email.toLowerCase()!=='somosmapoapp@gmail.com')throw new ServiceUnavailableException('La prueba está limitada al correo de MAPO');
    if(!this.ready)throw new ServiceUnavailableException('Falta SMTP_PASSWORD en el backend');
    const {default:nodemailer}=await import('nodemailer');
    const transport=nodemailer.createTransport({host:this.config.get('SMTP_HOST','smtp.gmail.com'),port:Number(this.config.get('SMTP_PORT',587)),secure:false,
      requireTLS:true,auth:{user:this.config.get('SMTP_USER','somosmapoapp@gmail.com'),pass:this.config.getOrThrow<string>('SMTP_PASSWORD')},connectionTimeout:10000});
    await transport.sendMail({from:{name:'MAPO',address:'somosmapoapp@gmail.com'},to:email,subject:'MAPO · Tu correo está listo',
      html:'<div style="background:#0E1B34;color:#F7F6F1;padding:40px;font:16px Arial"><h1 style="color:#59CFC4">MAPO</h1><h2>Todo listo para conectar.</h2><p>El backend ya puede enviar correos desde somosmapoapp@gmail.com.</p></div>'});
    return {sent:true};
  }
}
