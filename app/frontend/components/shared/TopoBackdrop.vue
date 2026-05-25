<template>
    <svg class="topo" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 300" preserveAspectRatio="none" aria-hidden="true">
        <g fill="none" stroke="#ffffff" stroke-opacity="0.10" stroke-width="1">
            <path d="M0,90 Q100,40 200,90 T400,90 T600,90 T800,90" />
            <path d="M0,130 Q120,80 240,130 T480,130 T720,130 T960,130" />
            <path d="M0,170 Q140,120 280,170 T560,170 T840,170" />
            <path d="M0,210 Q160,160 320,210 T640,210 T960,210" />
            <path d="M0,250 Q180,200 360,250 T720,250 T1080,250" />
        </g>
        <g fill="none" stroke="#fde68a" stroke-opacity="0.18" stroke-width="1">
            <path d="M-20,60 Q90,20 200,60 T420,60 T640,60 T860,60" />
            <path d="M0,290 Q130,260 260,290 T520,290 T780,290" />
        </g>
    </svg>
</template>

<style scoped>
.topo {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
}
</style>
