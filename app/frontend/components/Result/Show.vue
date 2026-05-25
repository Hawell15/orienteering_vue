<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">🏅 Rezultat</div>
                        <h1 class="title">
                            <a v-if="result.membership?.runner" :href="`/runners/${result.membership.runner_id}`">
                                {{ result.membership.runner.runner_name }} {{ result.membership.runner.surname }}
                            </a>
                        </h1>
                        <div class="subtitle">
                            <span v-if="result.membership?.club">
                                <a :href="`/clubs/${result.membership.club_id}`">{{ result.membership.club.club_name }}</a>
                            </span>
                            <template v-if="result.date">
                                <span class="dot">·</span>
                                <span>{{ result.date }}</span>
                            </template>
                        </div>
                        <div class="badges">
                            <span v-if="result.status" class="badge-pill">{{ formatStatus(result.status) }}</span>
                            <span v-if="result.wre_points" class="badge-pill">WRE {{ result.wre_points }} p</span>
                            <span v-if="result.ecn_points" class="badge-pill ecn">ECN {{ result.ecn_points }} p</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">🏆</div>
                <div class="stat-label">Locul</div>
                <div class="stat-value">{{ result.place }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">⏱</div>
                <div class="stat-label">Timpul</div>
                <div class="stat-value">{{ formatResultTime(result.time) }}</div>
            </div>
            <div class="stat-card accent" v-if="result.group">
                <div class="stat-icon">👥</div>
                <div class="stat-label">Grupa</div>
                <div class="stat-value"><a :href="`/groups/${result.group_id}`">{{ result.group.group_name }}</a></div>
            </div>
            <div class="stat-card accent" v-if="result.category">
                <div class="stat-icon">🎖</div>
                <div class="stat-label">Categoria îndeplinită</div>
                <div class="stat-value"><a :href="`/categories/${result.category_id}`">{{ result.category.category_name }}</a></div>
            </div>
        </div>

        <div class="section" v-if="result.group?.competition">
            <div class="section-card">
                <div class="section-card-title">📍 Competiție</div>
                <div class="info-grid">
                    <div class="info-row">
                        <span class="label">Denumirea</span>
                        <span class="value">
                            <a :href="`/competitions/${result.group.competition_id}`">{{ result.group.competition.competition_name }}</a>
                        </span>
                    </div>
                    <div class="info-row">
                        <span class="label">Data</span>
                        <span class="value">{{ result.date }}</span>
                    </div>
                    <div class="info-row">
                        <span class="label">Grupa</span>
                        <span class="value"><a :href="`/groups/${result.group_id}`">{{ result.group.group_name }}</a></span>
                    </div>
                </div>
            </div>
        </div>

        <div class="footer-actions">
            <button class="btn btn-outline-secondary" @click="goBack">← Înapoi</button>
            <div class="action-group">
                <button class="btn btn-success btn-sm" @click="editElement(result)">Editează</button>
                <button class="btn btn-danger btn-sm" @click="deleteResult(result.id)">Șterge</button>
            </div>
        </div>

        <Modal ref="modal" :result="modalElement" :isNew="false" @save="updateElement" />
    </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'

const result = ref({})
const resultId = ref("")
const modalElement = ref({})
const modal = ref(null)

onMounted(() => {
    resultId.value = window.location.pathname.split('/').pop();
    getData();
})

async function getData() {
    const res = await axios.get(`/results/${resultId.value}.json`)
    result.value = res.data;
}

function formatResultTime(seconds) {
    if (seconds == null) return ''
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    return (
        String(h).padStart(2, '0') + ':' +
        String(m).padStart(2, '0') + ':' +
        String(s).padStart(2, '0')
    );
}

function formatStatus(status) {
    const map = { confirmed: "Îndeplinit", pending: "În așteptare", unconfirmed: "Fără îndeplinire", capped: "Plafonat" }
    return map[status] || status
}

function editElement(r) {
    modalElement.value = {
        ...r,
        club_id: r.membership.club_id,
        runner_id: r.membership.runner_id,
        competition_id: r.group.competition_id,
        time: formatResultTime(r.time)
    }
    modal.value.show()
}

function updateElement(resultData, done) {
    axios.patch(`/results/${resultData.id}.json`, { result: resultData }).then(() => {
        getData();
        done()
    })
}

function deleteResult(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast rezultat?')) {
        axios.delete(`/results/${id}`).then(() => {
            window.location = document.referrer || "/results"
        })
    }
}

function goBack() {
    window.location = document.referrer || "/results"
}
</script>

<style scoped src="../shared/show.css"></style>
