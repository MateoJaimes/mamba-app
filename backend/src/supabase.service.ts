import { Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export function sessionAuthorization(authorization?: string): string | undefined {
  if (!authorization?.startsWith('Bearer ') || authorization.startsWith('Bearer sb_publishable_')) {
    return undefined;
  }
  return authorization;
}

@Injectable()
export class SupabaseService {
  private readonly baseUrl: string;
  private readonly key: string;
  constructor(private readonly config: ConfigService) {
    this.baseUrl=this.config.getOrThrow<string>('SUPABASE_URL');
    this.key=this.config.getOrThrow<string>('SUPABASE_PUBLISHABLE_KEY');
    if(!/^https:\/\/[^/]+\.supabase\.co$/.test(this.baseUrl))throw new Error('SUPABASE_URL inválida');
    if(!this.key.startsWith('sb_publishable_'))throw new Error('Usa la llave publicable de Supabase');
  }
  async request(path:string,method:string,token?:string,body?:unknown,extra:Record<string,string>={}) {
    token=sessionAuthorization(token);
    try {
      return await fetch(this.baseUrl+path,{method,headers:{apikey:this.key,'Content-Type':'application/json',...(token?{Authorization:token}:{}),...extra},
        body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(15000),redirect:'manual'});
    } catch {throw new ServiceUnavailableException('El servicio de datos no está disponible.');}
  }
  async user(token?:string):Promise<{id:string;email?:string}> {
    if(!sessionAuthorization(token))throw new UnauthorizedException('Inicia sesión');
    const r=await this.request('/auth/v1/user','GET',token);
    if(!r.ok)throw new UnauthorizedException('Sesión inválida o vencida');
    return r.json();
  }
  async uploadPhoto(userId:string,token:string,bytes:Buffer,fileName:string){
    const privateMedia = this.config.get('SUPABASE_PRIVATE_MEDIA') === 'true';
    const r=await fetch(`${this.baseUrl}/storage/v1/object/user-media/${userId}/${fileName}`,{method:'POST',headers:{apikey:this.key,Authorization:token,'Content-Type':'image/webp','Cache-Control':privateMedia ? '0' : '3600'},body:new Uint8Array(bytes),signal:AbortSignal.timeout(25000)});
    if(!r.ok)throw new ServiceUnavailableException('No se pudo guardar la foto');
    const access = privateMedia ? 'authenticated' : 'public';
    return `${this.baseUrl}/storage/v1/object/${access}/user-media/${userId}/${fileName}`;
  }

  async downloadPhoto(owner: string, file: string, token?: string) {
    await this.user(token);
    return this.request(`/storage/v1/object/authenticated/user-media/${owner}/${file}`, 'GET', token);
  }
}
