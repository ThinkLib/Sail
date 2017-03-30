let rf = require("fs");

function glsl(path) {

    function compile(code,filelist){
        let state = 0,include='',url='',temp='';
        for(let c of code){
            switch (c){
                case ';':
                case '{':
                case '}':
                    state = 0;
                    temp += c;
                    break;
                case '#':
                    state = 1;
                    break;
                case `"`:
                    if(state==9) state = 10;
                    else if(state==10) {
                        state = 0;
                        if(!filelist.includes(url)){
                            temp += compile(rf.readFileSync('shader/'+url,"utf-8"),filelist);
                            filelist.push(url);
                        }

                        url='';
                    }else temp += c;
                    break;
                default:
                    if(state == 8){
                        if(include == 'include') state=9;
                        else {
                            state = 0;
                            temp += include + c;
                        }

                        include = '';
                    }else if(state > 0&&state < 8) {
                        include += c;
                        state++;
                    }else if(state == 10) url += c;
                    else if(state == 0) temp += c;
            }
        }
        return temp;
    }

    return {

        transform( code, id ) {

            let filename = /shader\/(.*?glsl)$/.exec( id );
            if ( !filename ) return;
            code = compile(code,[filename[1]]);

            let transformedCode = 'export default ' + JSON.stringify(
                code.replace( /[ \t]*\/\/.*\n/g, '' ) // remove //
                    .replace( /[ \t]*\/\*[\s\S]*?\*\//g, '' ) // remove /* */
                    .replace( /\n{2,}/g, '\n' ) // # \n+ to \n
                ) + ';';
            return {
                code: transformedCode,
                map: { mappings: '' }
            };

        }

    };

}

export default {
    entry: 'main.js',
    indent: '\t',
    plugins: [
        glsl()
    ],
    // sourceMap: true,
    targets: [
        {
            format: 'umd',
            moduleName: 'Sail',
            dest: 'bin/sail.js'
        },
        {
            format: 'es',
            dest: 'bin/sail.module.js'
        }
    ]
};