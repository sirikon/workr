const init = (function(job_name, job_execution_id){
    const output_el = document.getElementById('job_execution_output');
    const status_el = document.getElementById('job_execution_finished');
    const keep_body_on_bottom_threshold = 0;
    let output_last_line_el = null;
    let dangling_carriage_return = false;
    let exiting = false;
    let done = false;
    let firstByteReceived = false;

    function subscribe_output() {
        let output_buffer = [];
        let buffer_interval = setInterval(() => {
            if (output_buffer.length === 0) { return; }
            append_output(output_buffer.join(''));
            output_buffer = [];
            if (done) {
                clearInterval(buffer_interval);
            }
        }, 100);
        httpGETStream('output_stream', (data, error) => {
            if (error) { return console.log("Error while reading output stream", error); }
            if (data === null) {
                !exiting && refresh_exit_code();
                done = true;
                return;
            }
            output_buffer.push(data);
        });
    }

    function listen_events() {
        window.addEventListener("beforeunload", () => { exiting = true; });
        document.onkeydown = (e) => {
            // If "End" key is pressed, means that the user wants to go to the
            // end of the document. If the scrolling in this scenario is animated
            // (like in Firefox), it won't get to the bottom if lines are being
            // written in the exact moment, so it will not get "hooked" to the
            // output stream.
            //
            // Forcing the scroll top to the bottom removes the animation, but
            // always gets hooked to the output stream.
            if (e.key === 'End' && !done) {
                e.preventDefault();
                document.body.scrollTop = document.body.scrollHeight;
            }
        }
    }

    function append_output(data) {
        if (!firstByteReceived) {
            // Streamed response always contains the complete output.
            // As soon as the first byte is received, remove everything and
            // start from scratch.
            output_el.innerHTML = '';
            output_last_line_el = document.createElement('pre');
            output_el.appendChild(output_last_line_el);
            firstByteReceived = true;
        }

        const keepBodyOnBottom = document.body.scrollTop + keep_body_on_bottom_threshold >= getBodyScrollTopMax();

        for (const char of data) {
            if (!dangling_carriage_return && char === '\r') {
                dangling_carriage_return = true;
                continue;
            }

            // \r\n
            if (dangling_carriage_return && char === '\n') {
                new_output_line();
                dangling_carriage_return = false;
                continue;
            }

            if (dangling_carriage_return) {
                new_output_line();
                dangling_carriage_return = false;
            }

            if (char === '\r') {
                new_output_line();
                continue;
            }
            
            output_last_line_el.textContent += char;
        }

        if (keepBodyOnBottom) {
            document.body.scrollTop = document.body.scrollHeight;
        }
    }

    function new_output_line() {
        // If the current line is empty, insert a newline in it before
        // inserting the new one, so it has a minimal height when displayed.
        if (output_last_line_el.textContent.length === 0) {
            output_last_line_el.textContent = '\n';
        }
        output_last_line_el = document.createElement('pre');
        output_el.appendChild(output_last_line_el);
    }

    function refresh_exit_code() {
        httpGETRequest('exit_code', (data, error) => {
            if (error) { return console.log("Error while refreshing exit code", error); }
            if (data === '') { return; }
            const exit_code = parseInt(data);
            status_el.classList.remove("is-running");
            if (exit_code === 0) {
                status_el.classList.add("is-finished");
                status_el.innerHTML = 'Finished';
            } else {
                status_el.classList.add("is-failed");
                status_el.innerHTML = 'Failed';
            }
        });
    }
    
    function httpGETRequest(path, cb) {
        httpGET(path, (xhr, error) => {
            if (error) { return cb(null, error) };
            if (xhr.readyState === 4) { cb(xhr.response, null); }
        });
    }

    function httpGETStream(path, cb) {
        let byteCount = 0;
        httpGET(path, (xhr, error) => {
            if (error) { return cb(null, error) }
            if (xhr.readyState >= 3) {
                const receivedBytes = xhr.response.substr(byteCount);
                cb(receivedBytes, null);
                byteCount = xhr.responseText.length;
            }
            if (xhr.readyState === 4) {
                cb(null, null);
            }
        });
    }

    function httpGET(path, cb) {
        const xhr = new XMLHttpRequest();
        xhr.open('GET', `/api/job/${job_name}/execution/${job_execution_id}/${path}`);
        xhr.onreadystatechange = () => cb(xhr, null);
        xhr.addEventListener("error", (error) => cb(null, error));
        xhr.send();
    }

    function getBodyScrollTopMax() {
        if (document.body.scrollTopMax !== undefined) {
            return document.body.scrollTopMax
        }
        return document.body.scrollHeight - window.innerHeight;
    }

    subscribe_output();
    listen_events();
});
