/*
 * (C) Copyright Itude Mobile B.V., The Netherlands.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MBRESTServiceDataHandler.h"

/** retrieves and sends MBDocument instances to and from the MobblServer webservice proxy.

 * MobblServer is a JavaEE server component that provides high performance transformation and compression of XML payloads to and from third party webservices. MobblServer also contains checksum based security features. 
 * The MBMobbl1ServerDataHandler provides out-of-the-box network connectivity to a MobblServer instance running on a server. 
 * A typical use case is where MobblServer transforms parts of SOAP xml messages to a JSON format and passes them on to the mobile app. The reverse route also works, allowing apps to pass compact JSON messages to MobblServer which inflates them into SOAP xml messages.
 
*/
@interface MBMobbl1ServerDataHandler : MBRESTServiceDataHandler {

}



@end
